import express from "express";
import { createServer as createViteServer } from "vite";
import Database from "better-sqlite3";
import dotenv from "dotenv";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const db = new Database("building.db");
const defaultAuthApiBase = process.env.AUTH_API_BASE?.trim() || "http://localhost:8080/api";

type SessionUser = {
  id: number;
  fullName: string;
  email: string;
  role: "admin" | "resident" | "staff";
  unitNumber: string | null;
  tower: string | null;
  avatarUrl: string | null;
};

// Initialize database
db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    google_id TEXT UNIQUE,
    email TEXT UNIQUE,
    name TEXT,
    role TEXT DEFAULT 'resident',
    unit_id TEXT
  );

  CREATE TABLE IF NOT EXISTS units (
    id TEXT PRIMARY KEY,
    type TEXT,
    resident_name TEXT,
    status TEXT DEFAULT 'occupied',
    balance DECIMAL(10, 2) DEFAULT 0
  );

  CREATE TABLE IF NOT EXISTS incidents (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    description TEXT,
    zone TEXT,
    status TEXT DEFAULT 'open',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS billing (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    unit_id TEXT,
    amount DECIMAL(10, 2),
    category TEXT,
    status TEXT DEFAULT 'pending',
    due_date DATE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
`);

// Seed initial data if empty
const unitCount = db.prepare("SELECT COUNT(*) as count FROM units").get() as { count: number };
if (unitCount.count === 0) {
  const insertUnit = db.prepare("INSERT INTO units (id, type, resident_name, balance) VALUES (?, ?, ?, ?)");
  insertUnit.run("401", "Penthouse", "Alice Thompson", 0);
  insertUnit.run("402", "Suite", "John Doe", 1250.00);
  insertUnit.run("301", "Standard", "Michael Chen", 0);
  insertUnit.run("105", "Standard", "Mark Wilson", 2100.00);
}

async function startServer() {
  const app = express();
  const PORT = 3000;

  app.use(express.json());

  app.get("/downloads/android-apk", (req, res) => {
    const apkPath = path.resolve(
      __dirname,
      "../flutter_apartment/build/app/outputs/flutter-apk/app-release.apk",
    );

    if (!fs.existsSync(apkPath)) {
      res
        .status(404)
        .json({ message: "Release APK is not available yet. Build Flutter release first." });
      return;
    }

    res.download(apkPath, "skyline-residences-release.apk");
  });

  // API Routes
  app.get("/api/units", (req, res) => {
    const units = db.prepare("SELECT * FROM units").all();
    res.json(units);
  });

  app.get("/api/incidents", (req, res) => {
    const incidents = db.prepare("SELECT * FROM incidents ORDER BY created_at DESC").all();
    res.json(incidents);
  });

  app.post("/api/incidents", (req, res) => {
    const { title, description, zone } = req.body;
    const info = db.prepare("INSERT INTO incidents (title, description, zone) VALUES (?, ?, ?)").run(title, description, zone);
    res.json({ id: info.lastInsertRowid });
  });

  app.get("/api/billing/:unitId", (req, res) => {
    const bills = db.prepare("SELECT * FROM billing WHERE unit_id = ?").all(req.params.unitId);
    res.json(bills);
  });

  // Auth Routes (Mock for now, but structure for real OAuth)
  app.get("/api/auth/url", (req, res) => {
    const configuredAppUrl = process.env.APP_URL?.trim();
    const appUrl =
      configuredAppUrl && !configuredAppUrl.startsWith("MY_APP_URL")
        ? configuredAppUrl
        : `${req.protocol}://${req.get("host")}`;
    const googleClientId = process.env.GOOGLE_CLIENT_ID?.trim();

    if (!googleClientId || googleClientId === "mock_client_id") {
      res.status(503).json({
        message:
          "Google Sign-In is not configured. Set GOOGLE_CLIENT_ID in fe_react/.env and register the redirect URI in Google Cloud Console.",
      });
      return;
    }

    const redirectUri = new URL("/auth/callback", appUrl).toString();
    const params = new URLSearchParams({
      client_id: googleClientId,
      redirect_uri: redirectUri,
      response_type: "code",
      scope: "openid email profile",
      access_type: "offline",
      prompt: "consent",
    });
    const authUrl = `https://accounts.google.com/o/oauth2/v2/auth?${params}`;
    res.json({ url: authUrl });
  });

  app.get("/auth/callback", (req, res) => {
    void handleGoogleCallback(req, res);
  });

  // Vite middleware for development
  if (process.env.NODE_ENV !== "production") {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    app.use(express.static(path.join(__dirname, "dist")));
    app.get("*", (req, res) => {
      res.sendFile(path.join(__dirname, "dist", "index.html"));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on http://localhost:${PORT}`);
  });
}

startServer();

async function handleGoogleCallback(req: express.Request, res: express.Response) {
  const configuredAppUrl = process.env.APP_URL?.trim();
  const appUrl =
    configuredAppUrl && !configuredAppUrl.startsWith("MY_APP_URL")
      ? configuredAppUrl
      : `${req.protocol}://${req.get("host")}`;
  const redirectUri = new URL("/auth/callback", appUrl).toString();
  const code = typeof req.query.code === "string" ? req.query.code : "";
  const oauthError = typeof req.query.error === "string" ? req.query.error : "";
  const clientId = process.env.GOOGLE_CLIENT_ID?.trim() ?? "";
  const clientSecret = process.env.GOOGLE_CLIENT_SECRET?.trim() ?? "";

  if (oauthError) {
    res.send(renderPopupResponse({
      type: "OAUTH_AUTH_ERROR",
      message: `Google sign-in failed: ${oauthError}.`,
    }, "Google sign-in was cancelled or denied."));
    return;
  }

  if (!code) {
    res.send(renderPopupResponse({
      type: "OAUTH_AUTH_ERROR",
      message: "Missing Google authorization code.",
    }, "Missing Google authorization code."));
    return;
  }

  if (!clientId || !clientSecret) {
    res.send(renderPopupResponse({
      type: "OAUTH_AUTH_ERROR",
      message: "Google Sign-In is not fully configured on the React server.",
    }, "Google Sign-In is not fully configured."));
    return;
  }

  try {
    const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        code,
        client_id: clientId,
        client_secret: clientSecret,
        redirect_uri: redirectUri,
        grant_type: "authorization_code",
      }),
    });

    if (!tokenResponse.ok) {
      const message = await readErrorMessage(tokenResponse);
      throw new Error(`Unable to exchange Google auth code. ${message}`);
    }

    const tokenPayload = (await tokenResponse.json()) as {
      access_token?: string;
    };
    if (!tokenPayload.access_token) {
      throw new Error("Google token response did not include an access token.");
    }

    const profileResponse = await fetch("https://www.googleapis.com/oauth2/v2/userinfo", {
      headers: {
        Authorization: `Bearer ${tokenPayload.access_token}`,
      },
    });

    if (!profileResponse.ok) {
      const message = await readErrorMessage(profileResponse);
      throw new Error(`Unable to read Google profile. ${message}`);
    }

    const profile = (await profileResponse.json()) as {
      email?: string;
      name?: string;
      picture?: string;
    };

    if (!profile.email) {
      throw new Error("Google account email is missing.");
    }

    const user = await resolvePortalUser(profile.email, profile.name, profile.picture);
    res.send(renderPopupResponse({
      type: "OAUTH_AUTH_SUCCESS",
      user,
    }, "Authentication successful. This window should close automatically."));
  } catch (error) {
    const message = error instanceof Error ? error.message : "Google sign-in failed.";
    res.send(renderPopupResponse({
      type: "OAUTH_AUTH_ERROR",
      message,
    }, message));
  }
}

async function resolvePortalUser(email: string, fallbackName?: string, fallbackAvatarUrl?: string): Promise<SessionUser> {
  const response = await fetch(
    `${defaultAuthApiBase}/users/by-email?email=${encodeURIComponent(email)}`,
  );

  if (response.ok) {
    const user = (await response.json()) as SessionUser;
    return {
      ...user,
      avatarUrl: user.avatarUrl ?? fallbackAvatarUrl ?? null,
      fullName: user.fullName || fallbackName || email.split("@")[0],
    };
  }

  if (email.toLowerCase().endsWith("@fpt.edu.vn")) {
    throw new Error("FPT account could not be provisioned as admin.");
  }

  throw new Error("This Google account is not linked to any portal user.");
}

async function readErrorMessage(response: Response) {
  const raw = await response.text();
  try {
    const parsed = JSON.parse(raw) as { error_description?: string; error?: string; message?: string };
    return parsed.error_description || parsed.message || parsed.error || raw;
  } catch {
    return raw;
  }
}

function renderPopupResponse(payload: object, fallbackText: string) {
  const serialized = JSON.stringify(payload)
    .replace(/</g, "\\u003c")
    .replace(/>/g, "\\u003e")
    .replace(/&/g, "\\u0026");

  return `
    <html>
      <body>
        <script>
          const payload = ${serialized};
          if (window.opener) {
            window.opener.postMessage(payload, '*');
            window.close();
          } else {
            window.location.href = '/login';
          }
        </script>
        <p>${escapeHtml(fallbackText)}</p>
      </body>
    </html>
  `;
}

function escapeHtml(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

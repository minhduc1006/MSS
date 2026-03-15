import express from "express";
import { createServer as createViteServer } from "vite";
import Database from "better-sqlite3";
import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url";

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const db = new Database("building.db");

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
    const redirectUri = `${process.env.APP_URL}/auth/callback`;
    const params = new URLSearchParams({
      client_id: process.env.GOOGLE_CLIENT_ID || "mock_client_id",
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
    // In a real app, exchange code for tokens here
    res.send(`
      <html>
        <body>
          <script>
            if (window.opener) {
              window.opener.postMessage({ type: 'OAUTH_AUTH_SUCCESS' }, '*');
              window.close();
            } else {
              window.location.href = '/';
            }
          </script>
          <p>Authentication successful. This window should close automatically.</p>
        </body>
      </html>
    `);
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

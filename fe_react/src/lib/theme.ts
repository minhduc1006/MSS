const THEME_KEY = "mss-theme";

export type AppThemeMode = "light" | "dark";

export function getStoredTheme(): AppThemeMode {
  if (typeof window === "undefined") {
    return "light";
  }

  const value = window.localStorage.getItem(THEME_KEY);
  return value === "dark" ? "dark" : "light";
}

export function applyTheme(mode: AppThemeMode) {
  if (typeof document === "undefined") {
    return;
  }

  document.documentElement.classList.toggle("dark", mode === "dark");
  document.documentElement.style.colorScheme = mode;
}

export function setTheme(mode: AppThemeMode) {
  if (typeof window !== "undefined") {
    window.localStorage.setItem(THEME_KEY, mode);
  }
  applyTheme(mode);
}

export function initializeTheme() {
  const mode = getStoredTheme();
  applyTheme(mode);
  return mode;
}

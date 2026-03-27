const { app, BrowserWindow, ipcMain, screen } = require('electron');
const path = require('path');
const fs = require('fs');

let mainWindow;

// Data persistence
const dataPath = path.join(app.getPath('userData'), 'tamagotchi-data.json');

function loadData() {
  try {
    if (fs.existsSync(dataPath)) {
      return JSON.parse(fs.readFileSync(dataPath, 'utf8'));
    }
  } catch (e) {}
  return {
    happiness: 50,
    tasks: [],
    lastReset: new Date().toDateString(),
    totalCompleted: 0,
    creatureName: 'Mochi'
  };
}

function saveData(data) {
  try {
    fs.writeFileSync(dataPath, JSON.stringify(data, null, 2));
  } catch (e) {}
}

function createWindow() {
  // Get the primary display's work area (excludes macOS menu bar & dock)
  const { workAreaSize } = screen.getPrimaryDisplay();
  const screenW = workAreaSize.width;
  const screenH = workAreaSize.height;

  // Mochi's natural aspect ratio is ~2:3 (width:height)
  // Scale to fill the full screen height, capped so it never overflows
  const ASPECT_W = 2;
  const ASPECT_H = 3;

  let winH = Math.round(screenH * 0.92);          // 92% of screen height
  let winW = Math.round(winH * (ASPECT_W / ASPECT_H));

  // Never wider than the screen
  if (winW > screenW * 0.95) {
    winW = Math.round(screenW * 0.95);
    winH = Math.round(winW * (ASPECT_H / ASPECT_W));
  }

  // Hard floor so it never gets too tiny on small screens
  winW = Math.max(winW, 320);
  winH = Math.max(winH, 480);

  mainWindow = new BrowserWindow({
    width:  winW,
    height: winH,
    minWidth:  320,
    minHeight: 480,
    // No maxWidth/maxHeight — let it fill the screen naturally
    frame: false,
    transparent: true,
    alwaysOnTop: false,
    resizable: true,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
      preload: path.join(__dirname, 'preload.js')
    },
    icon: path.join(__dirname, 'assets', 'creature_happy.png'),
    titleBarStyle: 'hidden',
    vibrancy: 'under-window',
    visualEffectState: 'active'
  });

  // Pass the computed dimensions to the renderer so the UI can scale itself
  mainWindow.webContents.on('did-finish-load', () => {
    mainWindow.webContents.send('window-size', { width: winW, height: winH });
  });

  mainWindow.loadFile('index.html');

  mainWindow.on('closed', () => { mainWindow = null; });
}

app.whenReady().then(() => {
  createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

// IPC handlers
ipcMain.handle('load-data', () => loadData());
ipcMain.handle('save-data', (event, data) => { saveData(data); return true; });
ipcMain.on('close-window',    () => { if (mainWindow) mainWindow.close(); });
ipcMain.on('minimize-window', () => { if (mainWindow) mainWindow.minimize(); });
ipcMain.on('drag-window', (event, { x, y }) => {
  if (mainWindow) {
    const [wx, wy] = mainWindow.getPosition();
    mainWindow.setPosition(wx + x, wy + y);
  }
});

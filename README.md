



<div align="center">
<h1 style="font-size: 3rem; margin-bottom: 1.5rem;">
CLIP PASTE
</h1>
</div>

Clip Paste is a small utility app for Finder on macOS. It allows to paste images and text as images/text files in finder.

---

## Preview

<img width="484" height="395" alt="Clip Paste settings panel" src="https://github.com/user-attachments/assets/46e9f36c-45e4-43de-a048-be2eb6913ad4" />

Configure the app in Settings, or enable the optional menu bar icon for quick access.

---

## What Clip Paste Does

### Default Finder behavior
When you try to paste something that is **not** a file or a folder in Finder, nothing happens.

### With Clip Paste
When the app detects **text or an image** in the clipboard and you paste into Finder, it automatically creates:

- an image file, or  
- a text file  

directly in the folder where you attempted to paste.

---

## Customization

You can configure Clip Paste to match your workflow:

- Enable or disable image and text file creation
- Customize filename templates
- Choose Desktop, Downloads, Pictures, or a custom default folder when the shortcut is triggered outside Finder
- Save images as PNG, JPEG, TIFF, or HEIC; adjust compression quality for JPEG and HEIC
- Save text as UTF-8 plain text, RTF, or HTML
- Hide the Dock icon and optionally show a menu bar icon
- Enable or disable automatic update checks at launch
- Choose which keyboard shortcut activates the action

If a filename is already in use, Clip Paste adds a numbered suffix (for example, `Note (2).txt`) and keeps the existing file.

<img width="479" height="392" alt="Image settings" src="https://github.com/user-attachments/assets/c8687ddd-7f46-4229-a64a-7436b5e08b9e" />
<img width="480" height="390" alt="Text settings" src="https://github.com/user-attachments/assets/8e4bcb30-0adf-423e-944e-a5186c47eea3" />

---

## Installation

### Requirements
- **macOS 14.6 or newer**

### Steps
1. Go to the latest release:  
   https://github.com/EllandeVED/Clip-Paste/releases/latest

2. Download the `.zip` file from the Releases page.

3. Open the app. On first launch, macOS will show a security warning  
   (the app is not signed with a registered Apple Developer ID):

<img width="266" height="239" alt="Security warning" src="https://github.com/user-attachments/assets/70f15712-db61-4e88-b80d-cb4d459e64fe" />

4. Open **System Settings → Privacy & Security** and click **Open Anyway**:

<img width="722" height="630" alt="Privacy and Security panel" src="https://github.com/user-attachments/assets/45f84291-ed1a-44c2-b0ab-3c9fbfa83f30" />

5. (Optional but recommended) Move the app to your **Applications** folder.

The app is now ready to use.

---

## Updates

- Enable or disable **Check for updates at launch** in General settings.
- **Check for Updates…** remains available for manual checks even when automatic checks are disabled.
- Downloads require your approval; the app shows instructions for opening the downloaded update.

---

## Export and visibility options

- [x] Custom locations for the default save folder
- [x] PNG, JPEG, TIFF, and HEIC image export
- [x] Plain text, RTF, and HTML text export
- [x] A hide Dock icon option
- [x] A check-for-updates enable/disable option
- [x] An optional menu bar icon

Choose **Custom folder** in the save-location picker, then **Choose Folder…**. The app remembers the selected folder using a bookmark. If that folder becomes unavailable, saving reports an error so you can choose it again. Finder's current folder continues to take priority when Finder is frontmost.

PNG and TIFF are lossless exports. JPEG and HEIC have an adjustable quality setting. JPEG composites transparency onto a white background. HEIC encoding depends on the Mac's image-encoding support; choose another format if encoding fails.

RTF preserves fonts, emphasis, colors, and links when the source application supplies RTF/RTFD. HTML preserves supplied HTML, or exports available rich text. Plain text is used when richer content is unavailable. HTML-only content is not rendered to convert it to RTF, so the app does not load remote images or styles during conversion. Text export does not package embedded attachments into companion files.

Dock and menu bar preferences apply immediately. The menu bar icon offers Settings, manual update checks, and Quit. If both icons are hidden, reopen Clip Paste from Applications to reach Settings.

---

## License

This project is licensed under the **MIT License**.

Copyright (c) 2025 **EllandeVED**

---

Checkout https://github.com/EllandeVED/NumworksApplication



# 📰 HarshNewsApp — Offline-First News Reader (UIKit • MVVM • Core Data)

 <img width="814" height="443" alt="Screenshot 2026-02-27 at 2 26 38 PM" src="https://github.com/user-attachments/assets/44d9155d-ec3d-4294-a152-321692e7a99f" />


## 🚀 Overview

HarshNewsApp is a production-grade native iOS news application designed with modern architecture, high performance, and offline reliability in mind.  
It delivers real-time global news while remaining fully usable without internet connectivity.

Built entirely using **Swift + UIKit** with **no third-party libraries**, this project demonstrates clean engineering practices suitable for real-world large-scale apps.

---

## ✨ Key Features

- 🌐 Fetches latest headlines from global sources via NewsAPI  
- 📴 Offline-first experience using Core Data local persistence  
- 🔄 Silent background sync with automatic UI refresh  
- 🧭 Smooth navigation with clean UIKit design  
- 🖼️ Full article view using WebKit with loading progress  
- ⚡ Fast scrolling with advanced image caching  
- 📄 Pagination with request cancellation  
- 🌙 Adaptive Light / Dark mode support  

---

## 🧠 Architecture & Engineering

- 🧩 **MVVM Architecture** with clear separation of concerns  
- 💾 **Single Source of Truth** using local database  
- 🧵 Swift 6 strict concurrency compliance  
- 🔒 Thread-safe Core Data stack  
- 🧠 Equatable models to prevent unnecessary DB writes  
- 📱 MainActor-safe UI updates  

---

## 💾 Offline-First Data Flow

- ⚡ Works without internet  
- 🔋 Saves battery and bandwidth  
- 📚 Ensures consistent user experience  

---

## 🗄️ Core Data Implementation

- 🔒 Fully thread-safe DB manager  
- 🧵 Background write operations using `performBackgroundTask`  
- 🚫 Removed AppDelegate dependency  
- ⚡ Race-condition safe for Swift 6  

---

## 🖼️ Image Handling & Performance

- 🧠 Multi-layer caching (Memory + Disk)  
- ⛔️ URLSession task cancellation on cell reuse  
- ✨ No image flickering during fast scroll  
- 🔗 URL tracking via Associated Objects  

---

## 🌐 Networking Layer

- 📡 URLSession-based API integration  
- ❌ No third-party networking libraries  
- ⛔️ Cancelable requests for performance  
- 📄 Efficient pagination (15 items per page)  
- 🧠 Duplicate request prevention  

---

## 🎨 UI & UX Enhancements

- 📖 Large titles on Home screen only  
- 🖥️ Professional navigation behavior  
- 🖼️ Full-screen HD image viewer  
- 📊 WebView progress tracking  
- ⏳ Clean loader HUD with transparent background  
- 📲 Closure-based cell interactions (modern UIKit style)  

---

## 💰 Ads Showcase (All Major Formats)

This app demonstrates integration of **Google Mobile Ads (AdMob)**:

- 📌 Banner Ads  
- 📌 Interstitial Ads  
- 📌 Rewarded Ads  
- 📌 Native Ads  
- 📌 App Open Ads  

All formats implemented with smooth, non-blocking presentation.

---

## 🛠️ Technical Topics Covered

- 🌐 API Networking using URLSession  
- 🧩 MVVM Architecture  
- 💾 Offline Storage with Core Data  
- 🧵 Swift Concurrency (async/await ready)  
- 🖼️ Image Caching System  
- 📄 Pagination & Request Management  
- 🔔 Background Tasks  
- 🚫 No Third-Party Libraries  

---

## 🔥 Platform & Compatibility

- 📱 Minimum Target: **iOS 17+**  
- 🧠 Swift 6 Ready  
- ✨ Compatible with modern iOS UI standards  

---

## 🌍 Data Source

- 📰 NewsAPI — https://newsapi.org  

---

## 👨‍💻 Developer

**Harsh Darji — Senior iOS Engineer (5+ yrs)**  

📧 dev.iharsh1008@gmail.com  
📱 +91 9662108047  

🌐 Portfolio: https://dev1008iharsh.github.io/  
💼 LinkedIn: https://www.linkedin.com/in/dev1008iharsh/  
🐙 GitHub: https://github.com/dev1008iharsh  

---

## ⭐ Highlights

- ⚡ Production-ready architecture  
- 🧠 Clean, maintainable codebase  
- 📴 Reliable offline experience  
- 🚀 Optimized for real-world scale  

---

⭐ If you find this project useful, consider giving it a star!


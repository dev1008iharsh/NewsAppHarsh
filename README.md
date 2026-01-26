![abc](https://github.com/dev1008iharsh/NewsAppHarsh/assets/155307551/c8dc65fa-827f-4c7e-992d-521562357785)

Topics I used i this App:
1.Fetching Data from API using URLSession
2.MVVM Architecture:
3.Offline Functionality with Core Data
4. No Third-Party Libraries
5. To name but a few

Stay informed and connected with the latest news from around the globe with HarshNewsApp, a sleek and intuitive news app designed to bring the world to your fingertips. Whether you're a news enthusiast or just looking to stay up-to-date, HarshNewsApp has you covered with its user-friendly interface and powerful features.(https://newsapi.org - for getting news from server)

1.Stay Updated Anytime, Anywhere:
HarshNewsApp fetches the latest news articles from top sources across the internet, ensuring you're always in the know about current events, trending topics, and breaking news. With just a tap, dive into a world of information right from your iPhone.

2.Seamless Offline Access:
Even when you're offline or experiencing connectivity issues, HarshNewsApp keeps you connected to the news you love. Thanks to its innovative offline functionality, the app seamlessly stores previously viewed articles on your device using cutting-edge technology, allowing you to access and read them whenever and wherever you are, without missing a beat.

3.Elegant Design, Effortless Navigation:
Experience the news in style with HarshNewsApp's elegant and intuitive design. Effortlessly navigate through articles, swipe between categories, and discover new topics with ease. Whether you're browsing the latest headlines or delving into specific topics of interest, HarshNewsApp offers a smooth and enjoyable reading experience tailored to your preferences.

4. No Fuss, No Frills – Just News:
HarshNewsApp prides itself on simplicity and reliability. With no intrusive ads or distractions, the focus remains squarely on delivering high-quality news content that informs, inspires, and engages you every step of the way.
Experience the power of knowledge with HarshNewsApp – your trusted companion for all things news-related. Explorer now and Read millions worldwide news and stay informed, connected, and inspired, one headline at a time.

🔥 What’s New in This Update (Big Refactor + Modern iOS Standards) 🛠️⚡

🧩 System & Compatibility Upgrade
	•	✅ Minimum iOS Target: iOS 17 📌
	•	✅ Fully Compatible with iOS 26 🧊✨ (Liquid Glass design vibe ready!)
	•	✅ Swift 6 Strict Concurrency compliant 🧠⚙️
	•	✅ Fixed Sendable warnings across Singleton classes 🛡️

  🗄️ Core Data (DBManager) — Fully Refactored & Thread-Safe 💾🔒
	•	🔁 DBManager હવે self-contained છે (AppDelegate dependency removed) 🧹
	•	🧵 Thread-safe Core Data stack + Sendable ready ✅
	•	🚫 Removed lazy var persistentContainer to avoid Swift 6 race condition issues ⚠️
	•	⚡ All write operations (save/delete) background માં performBackgroundTask વડે 🏎️
	•	🧠 deleteAllData માં completion handler add કરીને sequence fix:
Delete ➝ Save ➝ Refresh UI ✅ (No UI freeze / no data race) 🧊

🏗️ Offline-First + Single Source of Truth Architecture 📚✅

New Flow:
📥 Load Offline Data ➝ 🌐 Silent Background API Fetch ➝ 💾 Update DB ➝ 🔄 Refresh UI
	•	🟰 Article model માં Equatable add કર્યું
	•	🧠 Smart optimization:
જો API data == Local DB data ➝ DB write skip 🚫💾 (Battery + performance saver 🔋⚡)
	•	🎯 MainActor warnings fix કરીને UI updates always on Main Thread 🧵📱

  🖼️ Image Loading & Multi-Layer Caching (No Flicker!) ✨📸
	•	🔥 Fixed cell reuse image flickering issue 🧊
	•	loadImage() હવે URLSessionDataTask return કરે છે (task cancel support) ⛔️
	•	UIImageView extension with Associated Objects:
	•	current URL track કરે છે 🔗
	•	old task cancel કરે છે જ્યારે cell reuse થાય ♻️
	•	🧠 Memory + Disk caching = super fast scrolling ⚡🧠

  🧿 New UI Components & UX Enhancements 🎨😍

🖼️ HpdImageViewer (Full Screen HD Viewer)
	•	📌 Single file refactor
	•	⚡ async/await HD loading
	•	❌ Top-right Close (X) button for clean UX


  🌐 WebViewVC Improvements
	•	🛠️ Fixed NSInvalidUnarchiveOperationException (WebKit linking fix) ✅
	•	📊 Added UIProgressView with KVO loading progress
	•	🏷️ Navigation title auto sync with webpage title


  ⏳ LoaderManager Upgrade
	•	✅ Updated to @MainActor
	•	🌫️ Removed full-screen dimming background
	•	🎯 Transparent + center HUD (cleaner look)
	•	📝 Multi-line message support + auto-scaling font


  🧭 Navigation & UI Logic Cleanup 🧼✨
	•	🏠 Large Titles only on Home screen
	•	🔙 Other screens = normal titles (more professional feel) 🎯


  🧠 Cell Interaction Refactor (Modern UIKit Style) 📲✅
	•	🚫 Removed old sender.tag pattern
	•	✅ Implemented Closures / Callbacks for:
	•	📌 Read More tap
	•	🖼️ Image tap
	•	🔗 Navigation now uses direct URL strings (no tag dependency)


  🚀 Networking + Pagination Optimized ⚡📡
	•	📴 NetworkMonitor improved:
	•	No unnecessary alert on app launch
	•	Correct offline/online alert handling
	•	🧠 ApiManager returns URLSessionDataTask (cancelable requests)
	•	🏎️ NewsViewModel cancels previous tasks during fast scrolling
	•	📄 Pagination improved:
	•	isLoading flag to prevent duplicate calls
	•	Fetches 15 records per page ✅


  🧰 Topics / Tech Used in This App 🧠🛠️
	•	✅ URLSession Networking 🌐
	•	✅ MVVM Architecture 🧩
	•	✅ Offline-First with Core Data 💾
	•	✅ Thread-Safe Core Data + Swift 6 Concurrency 🧵
	•	✅ Image Caching (Memory + Disk) 🖼️⚡
	•	✅ No Third-Party Libraries 🚫📦


  🌟 Why You’ll Love HarshNewsApp 💙📰

✨ Clean UI • ⚡ Fast scrolling • 📴 Offline access • 🧠 Smart caching • 🔒 Safe concurrency • 📱 iOS 26 ready



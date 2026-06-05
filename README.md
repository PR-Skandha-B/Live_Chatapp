# Real-Time Chat Application

Cross-platform real-time chat app with group messaging, direct messages, read receipts, and emoji reactions.

**Live Demo**: [https://https://live-chatapp-ekizwf2na-rsb-207-projects.vercel.app](https://https://live-chatapp-ekizwf2na-rsb-207-projects.vercel.app)  
**Backend**: [https://livechatapp-production-dc3a.up.railway.app](https:livechatapp-production-dc3a.up.railway.app)  
**GitHub**: [https://github.com/PR-Skandha-B/Live_Chatapp.git](https://github.com/PR-Skandha-B/Live_Chatapp.git)

## Tech Stack

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js
- **Real-time**: Socket.io (WebSocket)
- **Database**: MongoDB
- **Auth**: JWT
- **Deployment**: Railway

### Frontend
- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **Storage**: Hive (local)
- **UI**: Material 3
- **Deployment**: Netlify (Web build)

---

## Features

✅ **Real-time Messaging**
- WebSocket-based communication via Socket.io
- Persistent connections for instant message delivery
- Room isolation (group chats & DMs)

✅ **Read Receipts**
- Per-user tracking of who has seen messages
- Visual indicators (single ✓ = sent, double ✓✓ = seen)
- Blue double-tick on sent messages

✅ **Emoji Reactions**
- React to messages with 100+ emojis
- Toggle emoji on/off
- Exchange emojis (switch from one to another)
- Real-time reaction updates

✅ **Message Threading**
- Swipe-to-reply on messages
- Quoted message previews
- Threaded conversation view

✅ **Direct Messaging**
- One-on-one private conversations
- Auto-create DM rooms on first message
- Per-user message visibility (soft delete)

✅ **Typing Indicators**
- See when others are typing
- Real-time status updates
- Auto-clear after 3 seconds

✅ **Room Management**
- Create group chat rooms
- Join via invite code
- Edit room name/description (admin only)
- View room members

✅ **Message Features**
- Delete messages (sender only)
- Forward to other rooms
- Message history (last 50 messages)
- Timestamp on each message

✅ **Authentication**
- JWT-based user authentication
- Secure password hashing (bcrypt)
- Login & registration
- Token persistence (local storage / Hive)

---

---

## Screenshots

### Login & Authentication
![Login Screen](Screenshots/Login_page.png)

### App Home Screen
![App Screen](Screenshots/App_Home_Screen.png)

### Options
![Chat Screen](Screenshots/User_Options.png)

### Rooms List & Home Screen
![Rooms List](Screenshots/Room_Details.png)

### Chat with Reactions & Read Receipts
![Chat Screen](Screenshots/Reactions.png)

### User Profile Edit
![Rooms List](Screenshots/Profile_Edit.png)

---

## Architecture

```mermaid
flowchart LR

    subgraph Frontend [Flutter Frontend]
        A[Login Screen]
        B[Rooms List]
        C[Chat Screen]
        D[Provider State Management]
    end

    subgraph Backend [Node.js + Express Backend]
        E[Auth Routes]
        F[Room Routes]
        G[Socket.io Handlers]
        H[Data Models]
    end

    subgraph Database [MongoDB]
        I[(User Profiles)]
        J[(Message Storage)]
        K[(Room Configuration)]
    end

    A -->|HTTP| E
    B -->|HTTP| F
    C <-->|WebSocket| G

    E --> H
    F --> H
    G --> H

    H --> I
    H --> J
    H --> K

    D --> C
    G -->|Real-time Events| C
```
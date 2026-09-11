KisanFlow AI

Tagline:
"Smart Slots. Shorter Queues. Better Procurement."

Overview
KisanFlow AI is a prototype for smart procurement-centre management:
- AI Smart Slot Recommendation
- Real-Time Queue Management
- Real-Time Wait-Time Prediction

This repo contains:
- frontend/: React + Vite app (Farmer & Admin UI)
- backend/: Node.js + Express REST APIs, JWT auth, MySQL models
- ai-service/: Flask lightweight service for slot recommendation and wait prediction
- database/: MySQL schema and seed data scripts

Quick start (dev)
1. Create a MySQL instance and user.
2. Copy .env.example -> .env and fill values.
3. Run database/schema.sql to create tables and seeds.
4. Start AI service:
   cd ai-service
   python -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   python app.py
5. Start backend:
   cd backend
   npm install
   npm run dev
6. Start frontend:
   cd frontend
   npm install
   npm run dev

See database/README for more details on seeding.

AI service note
- The Flask service exposes /recommend-slot and /predict-wait using historical CSV-backed factors.

Demo mode note
- Current seed and historical CSV are lightweight placeholders for demo flow; expand to 30+ farmers and 100+ historical rows for stronger recommendations.

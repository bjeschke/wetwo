#!/bin/bash

echo "🧪 Testing Partner Connection Flow"
echo "===================================="

# Backend URL
BASE_URL="http://localhost:8080"

echo ""
echo "1️⃣ Creating User1..."
USER1_RESPONSE=$(curl -s -X POST $BASE_URL/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser1@example.com",
    "password": "TestPass123!",
    "name": "Test User One",
    "birthDate": "1990-01-01"
  }')

USER1_CODE=$(echo $USER1_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin).get('relationshipCode', 'N/A'))")
echo "✅ User1 created with code: $USER1_CODE"

echo ""
echo "2️⃣ Creating User2..."
USER2_RESPONSE=$(curl -s -X POST $BASE_URL/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser2@example.com",
    "password": "TestPass123!",
    "name": "Test User Two",
    "birthDate": "1992-02-02"
  }')

USER2_CODE=$(echo $USER2_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin).get('relationshipCode', 'N/A'))")
echo "✅ User2 created with code: $USER2_CODE"

echo ""
echo "===================================="
echo "📱 In der App würde jetzt folgendes passieren:"
echo ""
echo "1. User1 loggt sich ein mit:"
echo "   Email: testuser1@example.com"
echo "   Password: TestPass123!"
echo ""
echo "2. User1 navigiert zu 'Partner verbinden'"
echo ""
echo "3. User1 gibt den Code von User2 ein: $USER2_CODE"
echo ""
echo "4. User1 klickt auf 'Verbinden'"
echo ""
echo "5. User2 erhält eine Push-Benachrichtigung"
echo ""
echo "6. User2 öffnet die App und sieht die Einladung"
echo ""
echo "7. User2 klickt auf 'Annehmen'"
echo ""
echo "8. ✅ Beide User sind jetzt verbunden!"
echo ""
echo "===================================="

# Cleanup
echo ""
echo "Partner Codes für manuellen Test:"
echo "User1 Code: $USER1_CODE"
echo "User2 Code: $USER2_CODE"
import express from "express";
import axios from "axios";
import dotenv from "dotenv";
dotenv.config();

const app = express();
app.use(express.json());

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
console.log("Loaded Gemini API key:", GEMINI_API_KEY ? "Found ✓" : "NOT FOUND ✗");

if (!GEMINI_API_KEY) {
  console.error("ERROR: GEMINI_API_KEY is not set in .env file");
  process.exit(1);
}

const GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";

// System prompt to tailor responses for hydroponics
const HYDROPONIC_SYSTEM_PROMPT = `You are NaiBot, an AI assistant specialized in hydroponic farming. 
You provide expert advice about:
- Hydroponic systems (NFT, DWC, ebb and flow, drip systems)
- Plant nutrition and nutrient solutions
- pH management and water quality
- Common hydroponic problems and solutions
- Crop selection for hydroponic systems
- Equipment and setup recommendations

Keep responses concise (2-3 sentences max), practical, and focused on hydroponic farming.
Always mention relevant hydroponic best practices when applicable.`;

async function queryGemini(message) {
  try {
    const response = await axios.post(
      `${GEMINI_API_URL}?key=${GEMINI_API_KEY}`,
      {
        systemInstruction: {
          parts: [
            {
              text: HYDROPONIC_SYSTEM_PROMPT,
            },
          ],
        },
        contents: [
          {
            parts: [
              {
                text: message,
              },
            ],
          },
        ],
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: 200,
        },
      },
      {
        headers: {
          "Content-Type": "application/json",
        },
        timeout: 15000,
      }
    );

    let reply = response.data?.candidates?.[0]?.content?.parts?.[0]?.text || "No response";
    
    reply = reply
      .replace(/\*\*(.*?)\*\*/g, "$1")
      .replace(/\*(.*?)\*/g, "$1")
      .replace(/__(.*?)__/g, "$1")
      .replace(/_(.*?)_/g, "$1")
      .trim();

    return reply;
  } catch (error) {
    console.error("Gemini API error:", error.response?.data || error.message);
    throw error;
  }
}

app.post("/api/chat", async (req, res) => {
  const userMessage = req.body.message?.trim();
  
  if (!userMessage) {
    return res.status(400).json({ error: "Empty message" });
  }

  console.log(`📨 User message: "${userMessage}"`);

  try {
    const reply = await queryGemini(userMessage);
    console.log(`✅ Response sent successfully`);
    return res.json({ reply, model: "gemini-2.0-flash" });
  } catch (error) {
    console.error(`❌ Error: ${error.message}`);
    return res.status(500).json({
      error: "Failed to get response from NaiBot. Please try again.",
      details: error.message,
    });
  }
});

app.get("/api/health", (req, res) => {
  res.json({ status: "OK", message: "NaiBot backend is running" });
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`\n🚀 NaiBot (Hydroponic Specialist) running on http://0.0.0.0:${PORT}`);
  console.log(`🌱 Specialized in hydroponic farming advice`);
  console.log(`📌 Using model: Gemini 2.0 Flash`);
  console.log(`\n✓ Ready to receive messages at: http://0.0.0.0:${PORT}/api/chat\n`);
});
import express from "express";
import axios from "axios";
import dotenv from "dotenv";
dotenv.config();

const app = express();
app.use(express.json());

console.log("Loaded API key:", process.env.OPENROUTER_API_KEY ? "Found" : "Not found");

// List of fallback models (all free)
const MODELS = [
  "deepseek/deepseek-chat-v3.1:free",
  "mistralai/mistral-7b-instruct:free",
  "meta-llama/llama-3.1-8b-instruct:free"
];

// 🔧 Utility function to clean AI responses
function cleanReply(text) {
  if (!text) return "";
  // Remove token markers like <|begin_of_sentence|> or <|end_of_text|>
  return text.replace(/<\|.*?\|>/g, "").trim();
}

async function queryModel(model, message) {
  const response = await axios.post(
    "https://openrouter.ai/api/v1/chat/completions",
    {
      model,
      messages: [{ role: "user", content: message }],
      temperature: 0.7, // more natural responses
      max_tokens: 150,  // prevent huge, slow outputs
    },
    {
      headers: {
        Authorization: `Bearer ${process.env.OPENROUTER_API_KEY}`,
        "Content-Type": "application/json",
      },
      timeout: 10000, // ⏱️ set 15s timeout per model
    }
  );

 let reply = response.data?.choices?.[0]?.message?.content || "";
  reply = reply
    .replace(/<\/?s>/g, "")      // remove <s> and </s>
    .replace(/\[\/?s\]/g, "")    // remove [s] and [/s]
    .replace(/\*\*(.*?)\*\*/g, "$1") // remove **bold** markdown
    .replace(/\*(.*?)\*/g, "$1") // remove *italic* markdown
    .trim();

  return reply;
}

app.post("/api/chat", async (req, res) => {
  const userMessage = req.body.message?.trim();
  if (!userMessage) return res.status(400).json({ error: "Empty message" });

  // Try each model in order until one works
  for (const model of MODELS) {
    try {
      console.log(`Trying model: ${model}`);
      const reply = await queryModel(model, userMessage);
      if (reply) {
        console.log(`Responded with ${model}`);
        return res.json({ reply, model });
      }
    } catch (error) {
      console.warn(` ${model} failed:`, error.response?.data?.error?.message || error.message);
    }
  }

  res.status(500).json({ error: "All model endpoints failed. Please try again later." });
});

// Listen on all interfaces so your app/emulator can connect
app.listen(8080, "0.0.0.0", () => {
  console.log("Chat backend running on http://0.0.0.0:8080");
});

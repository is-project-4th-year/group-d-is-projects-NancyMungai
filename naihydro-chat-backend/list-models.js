import axios from "axios";
import dotenv from "dotenv";
dotenv.config();

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

if (!GEMINI_API_KEY) {
  console.error("ERROR: GEMINI_API_KEY not found in .env");
  process.exit(1);
}

async function listModels() {
  try {
    console.log("Fetching available models...\n");
    
    const response = await axios.get(
      `https://generativelanguage.googleapis.com/v1beta/models?key=${GEMINI_API_KEY}`,
      {
        timeout: 10000,
      }
    );

    const models = response.data.models || [];
    
    console.log(`Found ${models.length} models:\n`);
    
    models.forEach((model, index) => {
      console.log(`${index + 1}. ${model.name}`);
      if (model.displayName) {
        console.log(`   Display Name: ${model.displayName}`);
      }
      if (model.description) {
        console.log(`   Description: ${model.description}`);
      }
      console.log();
    });
    
  } catch (error) {
    console.error("Error fetching models:");
    console.error(error.response?.data || error.message);
  }
}

listModels();
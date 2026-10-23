"""
DaNang SmartTour AI — Backend Vision Expert
Multi-Cuisine Culinary Expert and Food Safety Inspector for Vietnam.
Enforces objective visual feature deconstruction without regional bias.
"""

import json
import re
from typing import Dict, Any, Optional, Tuple
from BE.models import Dish


class VisionExpert:
    # ─── Strict Visual Identification Guidelines ────────────────────
    VISUAL_RULES_PROMPT = """
You are a Senior Vietnamese Culinary Expert & Food Safety Inspector.
You are analyzing a photo of food or a restaurant menu taken in Da Nang, Vietnam.

IMPORTANT REALITY CONTEXT:
Da Nang is a bustling gastronomic hub that serves both Central Vietnamese specialties
AND popular regional dishes from Northern and Southern Vietnam (e.g. Bún chả Hà Nội,
Phở bò, Cơm tấm Sài Gòn, Bún bò Huế, Bún đậu mắm tôm, Nem lụi).
NEVER force a dish to be a Da Nang specialty if the visual evidence clearly shows another dish!

STRICT VISUAL DISCRIMINATION RULES:
1. Bún Chả Hà Nội vs. Bún Chả Cá Đà Nẵng:
   - "Bún Chả Hà Nội": Look for grilled pork patties (chả băm nướng than hoa) and/or grilled pork belly slices (chả miếng) floating in a warm amber dipping bowl of diluted fish sauce with sliced green papaya & carrot. Served with a separate plate of white rice vermicelli (bún) and a basket of fresh herbs (perilla, kinh giới).
     -> Proteins: PORK (grilled pork, pork fat). Broth: Fish sauce dipping broth. (Contains Pork, Fish Sauce. FORBIDDEN FOR HALAL/VEGAN).
   - "Bún Chả Cá Đà Nẵng": Look for fried golden fish cakes (chả cá chiên) or steamed fish cakes (chả cá hấp) placed ON TOP of noodles inside a large bowl with red/orange broth containing tomatoes, pineapple chunks, pumpkin, and cabbage.
     -> Proteins: FISH CAKES. Broth: Pork bone broth + fermented shrimp paste (mắm ruốc).

2. Phở Bò (Beef Noodle Soup): Flat rice noodles (bánh phở) in clear spiced broth with beef slices, scallions, cilantro.
3. Bún Bò Huế: Thick round noodles in spicy red lemongrass broth with beef shank, pork knuckle, crab patty (chả cua), blood curd.
4. Bánh Xèo: Crispy yellow turmeric pancake folded in half. If containing pork/shrimp -> Non-halal/Non-vegan. If mushrooms only -> Vegan.
5. Mì Quảng: Wide turmeric or white noodles, shallow rich broth, chicken/pork/shrimp, toasted sesame rice cracker (bánh tráng mè), and crushed roasted peanuts.

OUTPUT FORMAT REQUIREMENTS:
Return ONLY a valid JSON object without markdown code blocks, thoughts, or conversational text:
{
  "dish_name": "Exact Vietnamese Name (e.g. Bún Chả Hà Nội, Bún Chả Cá Đà Nẵng, Phở Bò, Mì Quảng Gà)",
  "dish_name_en": "Accurate English Name",
  "confidence": 0.95,
  "visual_cues": ["grilled pork patties in amber sauce", "separate vermicelli plate", "fresh perilla herbs"],
  "hidden_ingredients": "Grilled pork, pork fat, diluted fish sauce, pickled papaya",
  "contains_pork": true,
  "contains_peanut": false,
  "contains_seafood": false,
  "contains_gluten": false,
  "is_safe_for_halal": false,
  "requires_kitchen_confirmation": false,
  "verdict_level": "RED/YELLOW/GREEN",
  "action_advice": "1-2 assertive, punchy sentences instructing the tourist what to do.",
  "ask_waiter_vi": "Direct Vietnamese phrase for the tourist to show the waiter.",
  "ask_waiter_en": "English meaning of the question for the tourist."
}
"""

    @classmethod
    def get_vision_prompt(cls, traveler_diet: str = "None", traveler_allergy: str = "None") -> str:
        return f"""{cls.VISUAL_RULES_PROMPT}

Active Tourist Safety Profile:
- Faith / Diet: {traveler_diet}
- Food Allergy: {traveler_allergy}

Carefully inspect the image. Deconstruct hidden risks (stewed bone broths, animal lard, peanut garnishes, shrimp paste). Return JSON only.
"""

    @staticmethod
    def clean_json_response(raw_text: str) -> Optional[Dict[str, Any]]:
        """
        Strips deepseek CoT thinking, markdown formatting, and extracts valid JSON.
        """
        if not raw_text:
            return None
        text = raw_text.strip()

        # Remove <think>...</think> blocks if present
        text = re.sub(r"<think>[\s\S]*?</think>", "", text).strip()

        # Look for markdown codeblock
        code_block = re.search(r"```(?:json)?\s*([\s\S]*?)\s*```", text)
        if code_block:
            text = code_block.group(1).strip()

        # Look for outer curly braces
        brace_match = re.search(r"\{[\s\S]*\}", text)
        if brace_match:
            candidate = brace_match.group(0)
            try:
                return json.loads(candidate)
            except Exception:
                pass

        try:
            return json.loads(text)
        except Exception:
            return None

    @staticmethod
    def synthesize_dish_from_vision(
        payload: Dict[str, Any],
        fallback_id: int = 9999,
    ) -> Dish:
        """
        Constructs a real Dish object from Vision payload, honoring non-Da Nang origins.
        """
        dish_name_vi = payload.get("dish_name", "Món ăn đường phố")
        dish_name_en = payload.get("dish_name_en", "Street Food Dish")
        hidden_ing = payload.get("hidden_ingredients", "Ingredients identified by AI Vision")
        
        lower_ing = hidden_ing.lower()
        contains_pork = payload.get(
            "contains_pork",
            ("pork" in lower_ing or "heo" in lower_ing or "lợn" in lower_ing or "mỡ" in lower_ing or "chả nướng" in lower_ing)
        )
        contains_peanut = payload.get(
            "contains_peanut",
            ("peanut" in lower_ing or "đậu phộng" in lower_ing or "lạc" in lower_ing)
        )
        contains_seafood = payload.get(
            "contains_seafood",
            ("seafood" in lower_ing or "tôm" in lower_ing or "cá" in lower_ing or "mắm" in lower_ing)
        )
        is_safe_halal = payload.get("is_safe_for_halal", not contains_pork)
        requires_confirm = payload.get("requires_kitchen_confirmation", False)

        region = "Northern Vietnam" if "hà nội" in dish_name_vi.lower() else (
            "Southern Vietnam" if "sài gòn" in dish_name_vi.lower() else "Da Nang / Vietnam"
        )

        return Dish(
            id=fallback_id,
            name_vi=dish_name_vi,
            name_en=dish_name_en,
            hidden_ingredients=hidden_ing,
            contains_pork=contains_pork,
            contains_peanut=contains_peanut,
            contains_seafood=contains_seafood,
            is_safe_for_halal=is_safe_halal,
            requires_kitchen_confirmation=requires_confirm,
            origin_region=region,
        )

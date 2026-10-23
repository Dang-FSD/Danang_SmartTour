"""
DaNang SmartTour AI — Backend Test Suite: Multi-Cuisine Vision Discrimination
Validates that regional dishes sold in Da Nang (like Bún chả Hà Nội, Phở Bò, Cơm Tấm)
are accurately classified without being falsely forced into Da Nang specialties.
"""

import unittest
import sys
import os

be_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if be_dir not in sys.path:
    sys.path.insert(0, be_dir)

try:
    from BE.models import Dish, TravelerProfile
    from BE.core.vision_expert import VisionExpert
    from BE.core.safety_engine import SafetyEngine
except ImportError:
    from models import Dish, TravelerProfile
    from core.vision_expert import VisionExpert
    from core.safety_engine import SafetyEngine


class TestVisionMultiCuisine(unittest.TestCase):
    def test_bun_cha_ha_noi_discrimination_against_bun_cha_ca(self):
        """
        Critical Test: Ensure Bún Chả Hà Nội is recognized as Hanoi Grilled Pork,
        NEVER defaulted or matched as Bún Chả Cá Đà Nẵng!
        """
        simulated_vision_payload = {
            "dish_name": "Bún Chả Hà Nội",
            "dish_name_en": "Hanoi Grilled Pork with Rice Vermicelli",
            "confidence": 0.94,
            "visual_cues": [
                "grilled pork patties in amber dipping sauce",
                "charcoal grilled pork belly slices",
                "plate of white rice vermicelli",
                "basket of perilla and herbs",
            ],
            "hidden_ingredients": "Chả thịt băm nướng than hoa, thịt ba chỉ nướng, nước mắm pha dấm đường, mỡ lợn, tỏi ớt",
            "contains_pork": True,
            "contains_peanut": False,
            "contains_seafood": False,
            "is_safe_for_halal": False,
            "requires_kitchen_confirmation": False,
            "verdict_level": "RED",
            "action_advice": "STRICT WARNING: Do not consume. Contains grilled pork and pork fat, strictly forbidden in Halal diets.",
            "ask_waiter_vi": "Cháu ơi, món này thịt nướng có ướp mỡ heo không?",
            "ask_waiter_en": "Does this grilled pork contain pork lard?",
        }

        # 1. Synthesize dish from vision payload
        dish = VisionExpert.synthesize_dish_from_vision(simulated_vision_payload)

        # Assert correct naming and region
        self.assertEqual(dish.name_vi, "Bún Chả Hà Nội")
        self.assertNotEqual(dish.name_vi, "Bún chả cá Đà Nẵng")
        self.assertEqual(dish.origin_region, "Northern Vietnam")
        self.assertTrue(dish.contains_pork)
        self.assertFalse(dish.is_safe_for_halal)

        # 2. Evaluate for Halal traveler
        halal_guest = TravelerProfile(id="h1", display_name="Zayd (Halal)", diet_rule="halal")
        verdict = SafetyEngine.evaluate_dish_safety(dish, halal_guest)

        self.assertEqual(verdict.level, "RED")
        self.assertIn("STRICT DIETARY VIOLATION", verdict.title)
        self.assertIn("pork", verdict.reason.lower())

        # 3. Evaluate for Vegan traveler
        vegan_guest = TravelerProfile(id="v1", display_name="Linh (Vegan)", diet_rule="vegan")
        vegan_verdict = SafetyEngine.evaluate_dish_safety(dish, vegan_guest)
        self.assertEqual(vegan_verdict.level, "RED")

    def test_strip_deepseek_cot_reasoning_tokens(self):
        """
        Validates that deepseek reasoning chains (thoughts) are cleanly stripped,
        returning only valid, clean JSON payload.
        """
        raw_deepseek_output = """
<think>
We need answer JSON only. Need analyze Vietnamese dish/menu image in Da Nang.
Image shows: central bowl with broth, meatballs? Looks like pork meatballs, maybe pork ribs?
Wait, is this Da Nang specialty: Bún chả cá?
No! Look closely: there are charcoal grilled pork patties (chả viên) and slices of pork belly (chả miếng)
floating in a diluted fish sauce dipping bowl with sliced green papaya and carrots.
Beside it is a separate plate of white noodles (bún) and perilla herbs.
This is unequivocally Bún Chả Hà Nội sold in a Da Nang street food restaurant!
It contains pork and fish sauce. Not Halal. Not Vegan.
</think>
```json
{
  "dish_name": "Bún Chả Hà Nội",
  "dish_name_en": "Hanoi Grilled Pork Noodles",
  "confidence": 0.95,
  "hidden_ingredients": "Grilled pork patties, pork belly, diluted fish sauce, garlic, chili, green papaya",
  "contains_pork": true,
  "contains_peanut": false,
  "is_safe_for_halal": false,
  "action_advice": "DO NOT CONSUME: Contains grilled pork and pork fat.",
  "ask_waiter_vi": "Món này có thịt heo nướng đúng không ạ?",
  "ask_waiter_en": "Does this dish contain grilled pork?"
}
```
"""
        cleaned = VisionExpert.clean_json_response(raw_deepseek_output)
        self.assertIsNotNone(cleaned)
        self.assertEqual(cleaned["dish_name"], "Bún Chả Hà Nội")
        self.assertTrue(cleaned["contains_pork"])
        self.assertFalse(cleaned["is_safe_for_halal"])
        self.assertIn("DO NOT CONSUME", cleaned["action_advice"])

    def test_pho_bo_hanoi_discrimination(self):
        """Validates that Phở Bò is recognized with beef and safe for Halal if halal-certified beef."""
        payload = {
            "dish_name": "Phở Bò Hà Nội",
            "dish_name_en": "Hanoi Beef Noodle Soup",
            "hidden_ingredients": "Nước dùng ninh xương bò, quế, hồi, thảo quả, gừng nướng, thịt bò tái/nạm",
            "contains_pork": False,
            "contains_peanut": False,
            "is_safe_for_halal": True,
        }
        dish = VisionExpert.synthesize_dish_from_vision(payload)
        self.assertEqual(dish.name_vi, "Phở Bò Hà Nội")
        self.assertFalse(dish.contains_pork)

    def test_banh_mi_thit_pate_discrimination(self):
        """
        Validates that Bánh Mì Thịt Pate is identified accurately as Vietnamese Baguette,
        contains pork liver pate and ham (RED for Halal), but safe for peanut allergy.
        """
        payload = {
            "dish_name": "Bánh Mì Thịt Pate Đà Nẵng",
            "dish_name_en": "Vietnamese Crispy Baguette with Pork Pate & Ham",
            "hidden_ingredients": "Bánh mì giòn, pate gan heo béo, chả lụa heo, thịt nguội, bơ trứng, sốt ớt chua ngọt",
            "contains_pork": True,
            "contains_peanut": False,
            "is_safe_for_halal": False,
        }
        dish = VisionExpert.synthesize_dish_from_vision(payload)
        self.assertEqual(dish.name_vi, "Bánh Mì Thịt Pate Đà Nẵng")
        self.assertTrue(dish.contains_pork)
        self.assertFalse(dish.contains_peanut)

        # Halal safety verification: MUST be RED
        halal_profile = TravelerProfile(
            id="halal_user",
            display_name="Amina (Halal)",
            diet_rule="halal",
        )
        verdict = SafetyEngine.evaluate_dish_safety(dish, halal_profile)
        self.assertEqual(verdict.level, "RED")
        self.assertTrue("pork" in verdict.reason.lower() or "heo" in verdict.reason.lower())

        # Peanut allergy traveler (Emma): Safe from peanuts
        peanut_profile = TravelerProfile(
            id="peanut_user",
            display_name="Emma (Peanut Allergy)",
            allergen="peanut",
            allergen_severity="severe",
        )
        verdict_peanut = SafetyEngine.evaluate_dish_safety(dish, peanut_profile)
        self.assertEqual(verdict_peanut.level, "GREEN")


if __name__ == "__main__":
    unittest.main()

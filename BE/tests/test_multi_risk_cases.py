"""
DaNang SmartTour AI — Backend Test Suite: Multi-Risk & Zero False-Safety Edge Cases
Validates complex overlapping health/faith profiles and zero false-safety guarantees.
"""

import unittest
import sys
import os

# Ensure BE is importable
be_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if be_dir not in sys.path:
    sys.path.insert(0, be_dir)

try:
    from BE.models import Dish, TravelerProfile
    from BE.core.safety_engine import SafetyEngine
except ImportError:
    from models import Dish, TravelerProfile
    from core.safety_engine import SafetyEngine


class TestMultiRiskCases(unittest.TestCase):
    def setUp(self):
        self.bun_cha_ca = Dish(
            id=1,
            name_vi="Bún chả cá Đà Nẵng",
            hidden_ingredients="Nước dùng ninh xương heo, chả cá thu/thác lác, mắm ruốc, cà chua",
            contains_pork=True,
            contains_seafood=True,
            contains_peanut=False,
            is_safe_for_halal=False,
        )

        self.mi_quang_dac_biet = Dish(
            id=2,
            name_vi="Mì Quảng Đặc Biệt",
            hidden_ingredients="Thịt ba chỉ heo, tôm tươi, trứng cút, dầu đậu phộng, đậu phộng rang giã nhỏ",
            contains_pork=True,
            contains_seafood=True,
            contains_peanut=True,
            is_safe_for_halal=False,
        )

        self.banh_xeo_chay = Dish(
            id=3,
            name_vi="Bánh xèo nấm chay",
            hidden_ingredients="Bột gạo, nấm bào ngư, giá đỗ, dầu thực vật",
            contains_pork=False,
            contains_seafood=False,
            contains_peanut=False,
            contains_gluten=False,
            is_safe_for_halal=True,
        )

    def test_multi_allergy_peanut_and_seafood_on_mi_quang(self):
        """Multi-Risk: Peanut Allergy traveler evaluating Mì Quảng with pork, shrimp & peanuts"""
        traveler = TravelerProfile(
            id="mr1",
            display_name="Alex (Peanut + Shellfish)",
            allergen="peanut",
            allergen_severity="severe",
        )
        verdict = SafetyEngine.evaluate_dish_safety(self.mi_quang_dac_biet, traveler)
        self.assertEqual(verdict.level, "YELLOW")
        self.assertTrue(verdict.requires_kitchen_handoff)
        self.assertIn("DỊ ỨNG ĐẬU PHỘNG", verdict.chef_ticket_vi)

    def test_halal_and_cardiac_tourist_on_bun_cha_ca(self):
        """Multi-Risk: Halal + Cardiac Patient facing Bún chả cá (pork broth)"""
        traveler = TravelerProfile(
            id="mr2",
            display_name="Tariq (Halal & Cardiac)",
            diet_rule="halal",
            medical_condition="cardiac",
        )
        verdict = SafetyEngine.evaluate_dish_safety(self.bun_cha_ca, traveler)
        self.assertEqual(verdict.level, "RED")
        self.assertIn("STRICT DIETARY VIOLATION", verdict.title)

    def test_zero_false_safety_absolute_rule(self):
        """
        CRITICAL ARCHITECTURAL GUARANTEE: Zero False-Safety.
        A dish with pork MUST NEVER, EVER produce GREEN for a Halal traveler.
        """
        dishes_with_pork = [
            self.bun_cha_ca,
            self.mi_quang_dac_biet,
            Dish(id=10, name_vi="Bún Chả Hà Nội", hidden_ingredients="Thịt heo nướng", contains_pork=True, is_safe_for_halal=False),
            Dish(id=11, name_vi="Bánh tráng cuốn thịt heo", hidden_ingredients="Thịt heo ba chỉ", contains_pork=True, is_safe_for_halal=False),
            Dish(id=12, name_vi="Cơm tấm sườn nướng", hidden_ingredients="Sườn heo nướng, mỡ hành", contains_pork=True, is_safe_for_halal=False),
        ]
        halal_traveler = TravelerProfile(id="h_check", display_name="Halal Check", diet_rule="halal")

        for dish in dishes_with_pork:
            verdict = SafetyEngine.evaluate_dish_safety(dish, halal_traveler)
            self.assertNotEqual(
                verdict.level,
                "GREEN",
                f"FATAL SAFETY FAILURE: Dish '{dish.name_vi}' containing pork returned GREEN for Halal traveler!",
            )
            self.assertEqual(verdict.level, "RED")


if __name__ == "__main__":
    unittest.main()

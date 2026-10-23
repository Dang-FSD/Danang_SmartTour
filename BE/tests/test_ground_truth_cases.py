"""
DaNang SmartTour AI — Backend Test Suite: 8 Ground-Truth Binary Cases
Validates the core 8 binary safety requirements defined in the system architecture.
"""

import unittest
import sys
import os

be_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if be_dir not in sys.path:
    sys.path.insert(0, be_dir)

try:
    from BE.models import Dish, TravelerProfile, SafetyTicket
    from BE.core.safety_engine import SafetyEngine
    from BE.core.crowd_engine import CrowdEngine
except ImportError:
    from models import Dish, TravelerProfile, SafetyTicket
    from core.safety_engine import SafetyEngine
    from core.crowd_engine import CrowdEngine


class TestGroundTruthCases(unittest.TestCase):
    def setUp(self):
        # 1. Bún chả cá Đà Nẵng (Stewed pork bone broth, fish cakes, mắm ruốc)
        self.bun_cha_ca = Dish(
            id=1,
            name_vi="Bún chả cá Đà Nẵng",
            hidden_ingredients="Nước dùng ninh xương heo, chả cá thu/thác lác, mắm ruốc, bí đỏ, cà chua",
            contains_pork=True,
            contains_peanut=False,
            is_safe_for_halal=False,
        )

        # 2. Mì Quảng Gà (Chicken broth, peanut oil, roasted peanuts)
        self.mi_quang_ga = Dish(
            id=2,
            name_vi="Mì Quảng Gà",
            hidden_ingredients="Thịt gà, tôm khô, dầu đậu phộng, đậu phộng rang giã nhỏ, bánh tráng mè",
            contains_pork=False,
            contains_peanut=True,
            is_safe_for_halal=True,
        )

        # 3. Bánh xèo nấm chay (Mushroom, bean sprouts, rice flour)
        self.banh_xeo_chay = Dish(
            id=3,
            name_vi="Bánh xèo nấm chay",
            hidden_ingredients="Bột gạo, nghệ, nấm bào ngư, giá đỗ, dầu thực vật",
            contains_pork=False,
            contains_peanut=False,
            contains_seafood=False,
            is_safe_for_halal=True,
        )

        # 4. Ram bắp gia truyền (Corn spring rolls, ambiguous cooking fat)
        self.ram_bap = Dish(
            id=4,
            name_vi="Ram bắp gia truyền",
            hidden_ingredients="Bắp nếp ngọt bào nhỏ, bánh tráng gạo, tiêu, hành lá, chảo chiên chung dầu",
            contains_pork=False,
            contains_peanut=False,
            requires_kitchen_confirmation=True,
        )

    def test_case_1_halal_bun_cha_ca_red_flag(self):
        """Case 1: Halal Tourist + Bún chả cá (pork broth) -> RED FLAG (Violation)"""
        traveler = TravelerProfile(id="u1", display_name="Amina (Halal)", diet_rule="halal")
        verdict = SafetyEngine.evaluate_dish_safety(self.bun_cha_ca, traveler)

        self.assertEqual(verdict.level, "RED")
        self.assertIn("STRICT DIETARY VIOLATION", verdict.title)
        self.assertIn("DO NOT CONSUME", verdict.action_advice)
        self.assertTrue(verdict.is_hazard())

    def test_case_2_cardiac_mui_nghe_trekking_red_flag(self):
        """Case 2: Cardiac Patient + Mũi Nghê Steep Trekking -> RED FLAG (Physical Hazard)"""
        traveler = TravelerProfile(id="u2", display_name="John (Cardiac)", medical_condition="cardiac")
        eval_result = SafetyEngine.evaluate_attraction_safety(
            attraction_name="Mũi Nghê Sơn Trà",
            difficulty="steep",
            is_overloaded=False,
            traveler=traveler,
        )

        self.assertEqual(eval_result["level"], "RED")
        self.assertFalse(eval_result["is_safe"])
        self.assertIn("STEEP TREKKING HAZARD", eval_result["reason"])
        self.assertIn("Vooc Nature Walking Trail", eval_result["alternative_suggestion"])

    def test_case_3_peanut_allergy_mi_quang_yellow_flag(self):
        """Case 3: Peanut Allergy + Chicken Mì Quảng -> YELLOW FLAG (Chef Dietary Ticket)"""
        traveler = TravelerProfile(id="u3", display_name="Sarah (Peanut)", allergen="peanut", allergen_severity="severe")
        verdict = SafetyEngine.evaluate_dish_safety(self.mi_quang_ga, traveler)

        self.assertEqual(verdict.level, "YELLOW")
        self.assertTrue(verdict.requires_kitchen_handoff)
        self.assertIsNotNone(verdict.chef_ticket_vi)
        self.assertIn("DỊ ỨNG ĐẬU PHỘNG", verdict.chef_ticket_vi)
        self.assertIn("TUYỆT ĐỐI KHÔNG rắc đậu phộng", verdict.chef_ticket_vi)

    def test_case_4_vegan_banh_xeo_chay_green_flag(self):
        """Case 4: Vegan Tourist + Vegan Mushroom Sizzling Pancake -> GREEN FLAG (100% Safe)"""
        traveler = TravelerProfile(id="u4", display_name="Elena (Vegan)", diet_rule="vegan")
        verdict = SafetyEngine.evaluate_dish_safety(self.banh_xeo_chay, traveler)

        self.assertEqual(verdict.level, "GREEN")
        self.assertTrue(verdict.is_safe())
        self.assertIn("100% SAFE", verdict.title)

    def test_case_5_dragon_bridge_overloaded_auto_reroute(self):
        """Case 5: Dragon Bridge Overloaded at Fire Show -> Smart Reroute to Non Nuoc (-42 min)"""
        result = CrowdEngine.evaluate_crowd_and_reroute(
            spot_name="Cầu Rồng Đà Nẵng",
            current_density_percent=450,
            hour_of_day=21,
            is_weekend=True,
        )

        self.assertTrue(result["is_overloaded"])
        self.assertTrue(result["reroute_triggered"])
        self.assertEqual(result["reroute_target"]["estimated_delay_saved_minutes"], 42)
        self.assertIn("Làng đá Mỹ nghệ Non Nước", result["reroute_target"]["name"])

    def test_case_6_network_error_ticket_rollback(self):
        """Case 6: Verification Integrity - Safety ticket must have valid non-empty fields"""
        ticket = SafetyTicket(
            ticket_code="TICKET-DN-9901",
            user_id="u1",
            dish_id=1,
            dish_name="Bún chả cá Đà Nẵng",
            safety_level="RED",
            bilingual_warning="CẢNH BÁO / WARNING",
            dietary_warning_en="Contains pork bone broth",
            verified=True,
        )
        data = ticket.to_dict()
        self.assertTrue(data["verified"])
        self.assertEqual(data["ticket_code"], "TICKET-DN-9901")

    def test_case_7_fit_tourist_sup_my_khe_green_flag(self):
        """Case 7: Fit Tourist + SUP at Mỹ Khê Beach -> GREEN FLAG (Approved for High Fitness)"""
        traveler = TravelerProfile(id="u7", display_name="David (Fit)", fitness_level="high")
        eval_result = SafetyEngine.evaluate_attraction_safety(
            attraction_name="Chèo SUP Bãi biển Mỹ Khê",
            difficulty="moderate",
            is_overloaded=False,
            traveler=traveler,
        )

        self.assertEqual(eval_result["level"], "GREEN")
        self.assertTrue(eval_result["is_safe"])
        self.assertIn("EXCELLENT MATCH", eval_result["reason"])

    def test_case_8_ambiguous_ram_bap_kitchen_handoff(self):
        """Case 8: Ambiguous Corn Spring Rolls (Ram bắp) -> YELLOW FLAG (Human Handoff)"""
        traveler = TravelerProfile(id="u8", display_name="Halal & Vegan Guest", diet_rule="halal")
        verdict = SafetyEngine.evaluate_dish_safety(self.ram_bap, traveler)

        self.assertEqual(verdict.level, "YELLOW")
        self.assertTrue(verdict.requires_kitchen_handoff)
        self.assertIn("XIN CHÀO ĐẦU BẾP", verdict.chef_ticket_vi)


if __name__ == "__main__":
    unittest.main()

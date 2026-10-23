"""
DaNang SmartTour AI — Backend Test Suite: Database Schema & RLS Verification
Parses and validates the PostgreSQL schema file (BE/DB/Danang_SmartTour_DB.sql)
ensuring all 8 required tables, RLS policies, and columns are defined.
"""

import os
import unittest


class TestDatabaseSchema(unittest.TestCase):
    def setUp(self):
        self.sql_path = os.path.join(
            os.path.dirname(__file__), "..", "DB", "Danang_SmartTour_DB.sql"
        )
        self.assertTrue(os.path.exists(self.sql_path), f"SQL file not found at: {self.sql_path}")
        with open(self.sql_path, "r", encoding="utf-8") as f:
            self.sql_content = f.read().lower()

    def test_all_8_required_tables_defined(self):
        """Verifies that all 8 core tables exist in the PostgreSQL schema"""
        required_tables = [
            "profiles",
            "health_profiles",
            "dishes",
            "attractions",
            "itineraries",
            "itinerary_stops",
            "safety_tickets",
            "agent_logs",
        ]
        for table in required_tables:
            pattern = f"create table {table}"
            alt_pattern = f"create table if not exists {table}"
            self.assertTrue(
                pattern in self.sql_content or alt_pattern in self.sql_content,
                f"Missing required table definition: {table}",
            )

    def test_row_level_security_enabled(self):
        """Verifies RLS is enabled for user-private tables (profiles, safety_tickets)"""
        self.assertIn("alter table profiles enable row level security", self.sql_content)
        self.assertIn("alter table safety_tickets enable row level security", self.sql_content)

    def test_safety_ticket_has_essential_columns(self):
        """Verifies safety_tickets contains ticket_code, bilingual_warning, verified"""
        self.assertIn("ticket_code", self.sql_content)
        self.assertIn("bilingual_warning", self.sql_content)
        self.assertIn("verified", self.sql_content)

    def test_agent_logs_has_rollback_tracking(self):
        """Verifies agent_logs table tracks tool_name, success, and error_msg for rollback testing"""
        self.assertIn("tool_name", self.sql_content)
        self.assertIn("success", self.sql_content)
        self.assertIn("error_msg", self.sql_content)


if __name__ == "__main__":
    unittest.main()

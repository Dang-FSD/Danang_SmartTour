"""
DaNang SmartTour AI — Backend GIS & Crowd Rerouting Engine
Monitors live overtourism density and dispatches dynamic reroutes (SDG 11 & SDG 8).
"""

from typing import Dict, Any, List


class CrowdEngine:
    DRAGON_BRIDGE_OVERLOAD_THRESHOLD = 300  # Percentage capacity
    NON_NUOC_SAVED_MINUTES = 42

    @classmethod
    def evaluate_crowd_and_reroute(
        cls,
        spot_name: str,
        current_density_percent: int,
        hour_of_day: int = 21,
        is_weekend: bool = True,
    ) -> Dict[str, Any]:
        """
        Calculates overtourism status and dispatches reroute recommendations.
        """
        is_dragon_bridge = "cầu rồng" in spot_name.lower() or "dragon bridge" in spot_name.lower()
        is_fire_show_time = is_dragon_bridge and (20 <= hour_of_day <= 22) and is_weekend

        # Overloaded condition
        if current_density_percent >= cls.DRAGON_BRIDGE_OVERLOAD_THRESHOLD or is_fire_show_time:
            return {
                "spot_name": spot_name,
                "is_overloaded": True,
                "current_density_percent": current_density_percent,
                "status": "CRITICAL_OVERLOAD",
                "reroute_triggered": True,
                "reroute_target": {
                    "name": "Làng đá Mỹ nghệ Non Nước (Non Nuoc Stone Village)",
                    "category": "craft_village_sdg8",
                    "latitude": 16.0042,
                    "longitude": 108.2618,
                    "estimated_delay_saved_minutes": cls.NON_NUOC_SAVED_MINUTES,
                    "sdg_impact": "SDG 11 (Sustainable Cities) & SDG 8 (Decent Work & Heritage Preservation)",
                },
                "recommended_action": (
                    f"REROUTE DISPATCHED: High congestion detected at {spot_name} ({current_density_percent}%). "
                    f"Diverting traveler to Non Nuoc Stone Village saves {cls.NON_NUOC_SAVED_MINUTES} minutes in traffic."
                ),
            }

        return {
            "spot_name": spot_name,
            "is_overloaded": False,
            "current_density_percent": current_density_percent,
            "status": "NORMAL_CAPACITY",
            "reroute_triggered": False,
            "recommended_action": f"{spot_name} is currently within manageable crowd levels.",
        }

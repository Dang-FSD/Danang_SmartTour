"""
DaNang SmartTour AI — Backend Data Models
Encapsulates Dish, TravelerProfile, and SafetyTicket representations.
"""

from dataclasses import dataclass, field
from typing import Optional, List, Dict, Any
from datetime import datetime


@dataclass
class Dish:
    id: int
    name_vi: str
    name_en: Optional[str] = None
    hidden_ingredients: str = ""
    contains_pork: bool = False
    contains_peanut: bool = False
    contains_seafood: bool = False
    contains_egg: bool = False
    contains_gluten: bool = False
    is_safe_for_halal: bool = False
    requires_kitchen_confirmation: bool = False
    origin_region: str = "Da Nang / Central Vietnam"
    image_url: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "name_vi": self.name_vi,
            "name_en": self.name_en,
            "hidden_ingredients": self.hidden_ingredients,
            "contains_pork": self.contains_pork,
            "contains_peanut": self.contains_peanut,
            "contains_seafood": self.contains_seafood,
            "contains_egg": self.contains_egg,
            "contains_gluten": self.contains_gluten,
            "is_safe_for_halal": self.is_safe_for_halal,
            "requires_kitchen_confirmation": self.requires_kitchen_confirmation,
            "origin_region": self.origin_region,
        }


@dataclass
class TravelerProfile:
    id: str
    display_name: str
    diet_rule: Optional[str] = None          # 'halal', 'vegan', 'vegetarian', 'kosher', 'none'
    allergen: Optional[str] = None           # 'peanut', 'seafood', 'gluten', 'egg', 'none'
    allergen_severity: Optional[str] = None  # 'severe', 'moderate', 'mild'
    medical_condition: Optional[str] = None  # 'cardiac', 'asthma', 'hypertension', 'none'
    fitness_level: str = "moderate"          # 'low', 'moderate', 'high'
    preferred_language: str = "en"

    def is_halal(self) -> bool:
        return bool(self.diet_rule and self.diet_rule.lower() == "halal")

    def is_vegan(self) -> bool:
        return bool(self.diet_rule and self.diet_rule.lower() in ["vegan", "vegetarian"])

    def has_cardiac_condition(self) -> bool:
        return bool(self.medical_condition and "cardiac" in self.medical_condition.lower())

    def has_peanut_allergy(self) -> bool:
        return bool(self.allergen and "peanut" in self.allergen.lower())

    def is_severe_allergy(self) -> bool:
        return bool(self.allergen_severity and self.allergen_severity.lower() == "severe")


@dataclass
class SafetyTicket:
    ticket_code: str
    user_id: str
    dish_id: int
    dish_name: str
    safety_level: str  # 'RED', 'YELLOW', 'GREEN'
    bilingual_warning: str
    dietary_warning_en: str
    verified: bool = True
    created_at: datetime = field(default_factory=datetime.utcnow)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "ticket_code": self.ticket_code,
            "user_id": self.user_id,
            "dish_id": self.dish_id,
            "dish_name": self.dish_name,
            "safety_level": self.safety_level,
            "bilingual_warning": self.bilingual_warning,
            "dietary_warning_en": self.dietary_warning_en,
            "verified": self.verified,
            "created_at": self.created_at.isoformat(),
        }

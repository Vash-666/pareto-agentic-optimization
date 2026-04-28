#!/usr/bin/env python3
"""
router-agent.py — Smart Agent Router
Classifies incoming tasks and routes to the right agent.
Usage: python3 router-agent.py <task-description>
       python3 router-agent.py --test
"""

import sys
import json
import re
from pathlib import Path

# --- Configuration ---
SCRIPT_DIR = Path(__file__).parent.resolve()
CONTEXT_FILE = SCRIPT_DIR / "context" / "projects.json"
RULES_FILE = SCRIPT_DIR / "context" / "routing-rules.json"

DEFAULT_AGENT = "switch"

# --- Routing Rules ---
ROUTING_RULES = {
    "quality": {
        "keywords": ["quality", "score", "gate", "audit", "threshold", "metric",
                     "validation", "test", "check", "verify", "standard"],
        "agents": ["qualityguardian", "quality"],
        "description": "Quality assessment, gates, audits, and validation"
    },
    "content": {
        "keywords": ["write", "content", "post", "document", "readme", "github",
                     "social", "marketing", "announce", "blog", "article", "tweet"],
        "agents": ["content"],
        "description": "Content creation, documentation, social media, GitHub"
    },
    "architecture": {
        "keywords": ["architecture", "design", "structure", "system", "workflow",
                     "pipeline", "infrastructure", "plan", "schema"],
        "agents": ["switch", "quality"],
        "description": "System design, architecture planning, workflow design"
    },
    "product": {
        "keywords": ["product", "roadmap", "backlog", "feature", "priority",
                     "sprint", "release", "user story", "requirement"],
        "agents": ["product-manager", "switch"],
        "description": "Product management, backlog, roadmap, requirements"
    },
    "monitoring": {
        "keywords": ["monitor", "health", "status", "dashboard", "alert",
                     "heartbeat", "check", "watch", "track"],
        "agents": ["switch"],
        "description": "System monitoring, health checks, alerts, dashboard"
    },
    "overseight": {
        "keywords": ["kiwi", "oversight", "audit", "review", "gap", "diagnose",
                     "observe", "watch", "scan"],
        "agents": ["kiwi-2.6", "switch"],
        "description": "Product oversight, gap analysis, capability diagnosis"
    },
    "implementation": {
        "keywords": ["build", "implement", "create", "develop", "code", "script",
                     "tool", "deploy", "install", "configure"],
        "agents": ["switch"],
        "description": "Implementation, coding, scripting, deployment"
    }
}

# --- Agent-to-implementation mapping ---
AGENT_ALIASES = {
    "switch": "Switch (Chief Orchestrator)",
    "main": "Switch (Chief Orchestrator)",
    "quality": "QualityGuardian",
    "qualityguardian": "QualityGuardian",
    "content": "Content Agent",
    "grok": "Grok Bridge",
    "product": "Product Manager",
    "product-manager": "Product Manager",
    "kiwi-2.6": "Kiwi 2.6 (Product Oversight)",
    "kiwi": "Kiwi 2.6 (Product Oversight)",
    "scaffolder": "Scaffolder"
}

def classify_task(task):
    """Classify a task description into a routing category."""
    task_lower = task.lower()
    scores = {}
    
    for category, rule in ROUTING_RULES.items():
        score = 0
        for keyword in rule["keywords"]:
            if keyword in task_lower:
                score += 1
        if score > 0:
            scores[category] = score
    
    if not scores:
        return None, []
    
    # Sort by match score descending
    ranked = sorted(scores.items(), key=lambda x: x[1], reverse=True)
    best_category = ranked[0][0]
    all_categories = [c for c, s in ranked]
    
    return best_category, all_categories

def route(task):
    """Route a task to the appropriate agent."""
    category, all_cats = classify_task(task)
    
    if not category:
        return {
            "task": task,
            "category": "unknown",
            "agent": DEFAULT_AGENT,
            "agent_name": AGENT_ALIASES.get(DEFAULT_AGENT, "Switch"),
            "confidence": 0,
            "all_categories": [],
            "action": "manual_routing_required"
        }
    
    rule = ROUTING_RULES[category]
    agents = rule["agents"]
    confidence = len(all_cats) / (len(ROUTING_RULES) * 0.3)
    confidence = min(1.0, round(confidence, 2))
    
    return {
        "task": task,
        "category": category,
        "category_desc": rule["description"],
        "agent": agents[0],
        "agent_name": AGENT_ALIASES.get(agents[0], agents[0]),
        "agents": agents,
        "confidence": confidence,
        "all_categories": all_cats[:5],
        "action": "auto_route" if confidence >= 0.3 else "suggest_route"
    }

def test_mode():
    """Run through test cases to verify routing accuracy."""
    test_cases = [
        "Check quality score for pareto project",
        "Write a README for the new project",
        "Set up the architecture for batch processing",
        "Check system health and dashboard status",
        "Design the product roadmap for next quarter",
        "Build the smart router script",
        "Observe capability gaps in the monitoring system",
        "Run quality gates on pipeline-mvp",
        "Tweak the color scheme",
        "Create a GitHub announcement post",
    ]
    
    results = []
    for case in test_cases:
        result = route(case)
        results.append(result)
        agent = result.get("agent_name", "?")
        conf = result.get("confidence", 0)
        cat = result.get("category", "?")
        print(f"  [{cat}] {conf:.0%} → {agent:30s} | {case}")
    
    # Summary stats
    auto = sum(1 for r in results if r.get("action") == "auto_route")
    suggest = sum(1 for r in results if r.get("action") == "suggest_route")
    manual = sum(1 for r in results if r.get("action") == "manual_routing_required")
    print(f"\n  Auto-route: {auto}/10 | Suggest: {suggest}/10 | Manual: {manual}/10")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 router-agent.py <task-description>")
        print("       python3 router-agent.py --test")
        sys.exit(1)
    
    if sys.argv[1] == "--test":
        print("══════════════════════════════════════════════")
        print("  SMART ROUTER — Test Mode")
        print("══════════════════════════════════════════════")
        test_mode()
    else:
        task = " ".join(sys.argv[1:])
        result = route(task)
        
        print("══════════════════════════════════════════════")
        print("  SMART ROUTER")
        print("══════════════════════════════════════════════")
        print(f"  Task: {result['task']}")
        print(f"  Category: {result.get('category', 'unknown')}")
        if "category_desc" in result:
            print(f"  Type: {result['category_desc']}")
        print(f"  → Route to: {result['agent_name']}")
        print(f"  Confidence: {result['confidence']:.0%}")
        print(f"  Action: {result['action']}")
        
        if result.get("all_categories"):
            print(f"  Matched categories: {', '.join(result['all_categories'][:3])}")
        
        print("══════════════════════════════════════════════")

# Technical Documentation — Pipeline MVP

## Setup
1. Clone repo
2. Install dependencies: bash, jq, Python 3
3. Run: ./run-pipeline.sh pipeline-mvp review 70

## Architecture
- 3-agent system: Switch (orchestrator), QualityGuardian (gate), Content (docs)
- File-based state in context/projects.json
- Quality gates at 4 milestones: start=60, review=75, complete=85, production=90

## Execution
- ./run-pipeline.sh pipeline-mvp start 60
- ./run-pipeline.sh pipeline-mvp review 75
- ./run-pipeline.sh pipeline-mvp complete 85
- ./run-pipeline.sh pipeline-mvp production 90

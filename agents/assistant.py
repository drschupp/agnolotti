"""Agnolotti assistant agent using Claude Sonnet."""

from agno.agent import Agent
from agno.models.anthropic import Claude
from agno.tools.duckduckgo import DuckDuckGoTools

from db.session import get_agent_db

assistant = Agent(
    id="agnolotti-assistant",
    name="Agnolotti Assistant",
    model=Claude(id="claude-sonnet-4-20250514"),
    db=get_agent_db(),
    tools=[DuckDuckGoTools()],
    description="You are Agnolotti, a helpful AI assistant powered by Claude Sonnet.",
    instructions=[
        "Be concise and direct.",
        "Use tools when available to accomplish tasks.",
        "Search the web when the user asks about current events or needs up-to-date information.",
    ],
    add_history_to_context=True,
    num_history_runs=3,
    add_datetime_to_context=True,
    markdown=True,
)

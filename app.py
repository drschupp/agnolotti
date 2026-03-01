"""Agnolotti — AgentOS application."""

from dotenv import load_dotenv

load_dotenv()

from agno.os import AgentOS  # noqa: E402

from agents.assistant import assistant  # noqa: E402

agent_os = AgentOS(
    description="Agnolotti Agent System",
    agents=[assistant],
    tracing=True,
)

app = agent_os.get_app()

if __name__ == "__main__":
    agent_os.serve(app="app:app", reload=True)

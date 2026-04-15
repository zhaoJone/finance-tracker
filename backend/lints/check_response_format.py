"""
检查 api/ 层的所有路由是否使用统一的响应格式。
避免 Agent 随意返回裸字典或不一致的错误格式。
"""
import ast, sys, re
from pathlib import Path

ALLOWED_RETURNS = {"success_response", "error_response", "JSONResponse"}

def check(filepath: Path) -> list[str]:
    if "/api/" not in str(filepath):
        return []
    source = filepath.read_text()
    errors = []
    # 简单检查：api 层的 return {} 直接返回裸字典
    if re.search(r'^\s+return\s+\{', source, re.MULTILINE):
        errors.append(
            f"[响应格式违规] {filepath}\n"
            f"  API 路由不能直接 return 裸字典\n"
            f"  修复：使用 success_response(data) 或 error_response(msg, code)"
        )
    return errors

if __name__ == "__main__":
    errors = []
    for f in Path("src/api").rglob("*.py"):
        errors.extend(check(f))
    if errors:
        print("\n".join(errors))
        sys.exit(1)
    print("✅ 响应格式检查通过")

"""
层级依赖检查：确保后端各层不存在反向导入。
违反时输出含修复建议的错误信息，注入 Agent 上下文。
"""
import ast, sys
from pathlib import Path

LAYERS = ["schemas", "repository", "service", "api"]

def layer_of(path: Path) -> str | None:
    for layer in LAYERS:
        if f"/src/{layer}/" in str(path):
            return layer
    return None

def check(filepath: Path) -> list[str]:
    src_layer = layer_of(filepath)
    if not src_layer:
        return []
    src_idx = LAYERS.index(src_layer)
    errors = []
    try:
        tree = ast.parse(filepath.read_text())
    except SyntaxError:
        return []
    for node in ast.walk(tree):
        if isinstance(node, (ast.Import, ast.ImportFrom)):
            module = getattr(node, 'module', '') or ''
            names = [a.name for a in getattr(node, 'names', [])]
            targets = [module] + names
            for t in targets:
                for layer in LAYERS:
                    if f"src.{layer}" in t or f"/{layer}/" in t:
                        if LAYERS.index(layer) > src_idx:
                            errors.append(
                                f"[层级违规] {filepath}:{node.lineno}\n"
                                f"  {src_layer}/ 层不能导入 {layer}/ 层\n"
                                f"  修复方案：将此逻辑上移到 {layer}/ 层，\n"
                                f"  或通过依赖注入传入，而非直接 import"
                            )
    return errors

if __name__ == "__main__":
    errors = []
    for f in Path("src").rglob("*.py"):
        errors.extend(check(f))
    if errors:
        print("\n".join(errors))
        sys.exit(1)
    print("✅ 层级检查通过")

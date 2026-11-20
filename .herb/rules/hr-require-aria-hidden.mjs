import {
  BaseRuleVisitor,
  ParserRule,
  getStaticAttributeValue,
} from "@herb-tools/linter"

class HrRequireAriaHiddenVisitor extends BaseRuleVisitor {
  visitHTMLOpenTagNode(node) {
    if (
      node.tag_name?.value === "hr" &&
      getStaticAttributeValue(node, "aria-hidden") !== "true"
    ) {
      this.addOffense(
        "Decorative `<hr>` elements must include `aria-hidden=\"true\"`.",
        node.tag_name.location,
      )
    }

    super.visitHTMLOpenTagNode(node)
  }
}

export default class HrRequireAriaHiddenRule extends ParserRule {
  static ruleName = "dfe-a11y-hr-aria-hidden"

  check(result, context) {
    const visitor = new HrRequireAriaHiddenVisitor(this.ruleName, context)
    visitor.visit(result.value)
    return visitor.offenses
  }
}

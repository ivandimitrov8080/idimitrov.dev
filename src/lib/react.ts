import { ReactNode } from "react";

export const getText = (node: ReactNode | any) => {
  const props = node.props;
  if (!props) {
    return node;
  }
  const c = props.children || "";
  return typeof c === "string" ? c : c.map(getText).join("");
};

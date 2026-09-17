/** Types for rules.js, so the Runner can use the very same answers. */

export interface RuleField {
  question: string;
  options: string[];
}

export interface RuleTextField {
  index: number;
  label?: string;
  type?: string;
}

export interface Proposal {
  question: string;
  option: number;
  label: string;
  why: string;
}

export function normalize(text: unknown): string;
export function isWantedOption(label: string, wanted: string[]): boolean;
export function plan(input: { url: string; title?: string; fields: RuleField[]; app: Record<string, unknown> }): Proposal[];
export function targetAudience(labels: string[]): number[];
export function categoryChoice(labels: string[]): number;
export function textAnswers(fields: RuleTextField[], app: Record<string, unknown>): Array<{ index: number; value: string; why: string }>;

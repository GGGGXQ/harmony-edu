import localUnitTest from './LocalUnit.test';
import markdownTest from './MarkdownParser.test';

export default function testsuite() {
  localUnitTest();
  markdownTest();
}
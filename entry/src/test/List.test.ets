import GamePlayTest from './GamePlay.test'
import localUnitTest from './LocalUnit.test';

export default function testsuite() {
  localUnitTest();
  GamePlayTest()
}
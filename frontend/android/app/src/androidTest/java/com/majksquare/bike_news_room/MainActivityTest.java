package com.majksquare.bike_news_room;

import androidx.test.platform.app.InstrumentationRegistry;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import pl.leancode.patrol.PatrolJUnitRunner;

// Bridges Patrol's Dart-side test runner to Android instrumentation.
// PatrolJUnitRunner enumerates the @PatrolTest declarations from
// integration_test/app_test.dart at runtime via the patrol_app_service
// channel, then runs each one as a parameterised JUnit test. This
// mirrors the canonical Patrol 3.x bootstrap recipe.
@RunWith(Parameterized.class)
public class MainActivityTest {
    @Parameterized.Parameters(name = "{0}")
    public static Object[] testCases() {
        PatrolJUnitRunner instrumentation =
            (PatrolJUnitRunner) InstrumentationRegistry.getInstrumentation();
        instrumentation.setUp(MainActivity.class);
        instrumentation.waitForPatrolAppService();
        return instrumentation.listDartTests();
    }

    public MainActivityTest(String dartTestName) {
        this.dartTestName = dartTestName;
    }

    @Test
    public void runDartTest() {
        PatrolJUnitRunner instrumentation =
            (PatrolJUnitRunner) InstrumentationRegistry.getInstrumentation();
        instrumentation.runDartTest(dartTestName);
    }

    private final String dartTestName;
}

/*
 * Module Primer
 *
 * This primer introduces the concept of modules, a concept for encapsulating
 * code for use by other code.  It covers:
 *   how to define a module
 *   namespace control within a module
 *   external access to a module's symbols
 *   namespace control when using a module, including:
 *     unlimited
 *     explicit exclusion of symbols
 *     explicit inclusion of symbols
 *     renaming included symbols
 *   cross-file module access
 */


/* A module is a grouping of code - each program consists of at least one
   module, and every symbol is associated with some module.  If all the code of
   a file is not enclosed in an explicit module, defined using the 'module'
   keyword, then the file itself is treated as a module with the same name as
   the file (minus the .chpl suffix).
 */
module modToUse {

  /* In this case, foo is a public module-level variable that is defined within
     the module modToUse */
  var foo = 12;

  /* As is bar. */
  var bar: int = 2;

  /* A symbol can be declared "private" - this means that only code defined
     within the same scope as the definition of this symbol can access it.

     Here, hiddenFoo is a private global variable, which is only accessible by
     symbols defined within modToUse
  */
  private var hiddenFoo = false;


  /* baz is a public function which is defined within modToUse */
  proc baz (x, y) {
    return x * (x + y);
  }

  /* hiddenBaz is a private function, which is also only accessible by symbols
     defined within modToUse.
  */
  private proc hiddenBaz(a) {
    writeln(a);
    return a + 3;
  }


  /* A module defined within another module is called a nested module.  These
     submodules can refer to symbols defined within their parent module, but
     their parent module can't directly access the contents of the nested
     module.  We will cover how to access the contents of other modules later in
     this primer.
  */
  module Inner1 {
    /* The variable foobar references modToUse's foo and bar variables. */
    var foobar = foo + bar;
  }

  module Inner2 {
    /* Since the module Inner2 is defined within modToUse, it can access the
       private variable hiddenFoo and the private function hiddenBaz.  However,
       any private symbol defined within Inner2 will not be visible within
       scopes defined outside of Inner2.
     */

    private var innerOnly = -17;
    var canSeeHidden = !hiddenFoo;
  }

  // In the current implementation, private cannot be applied to type
  // definitions; type aliases, and declarations of enums, records, and
  // classes cannot be declared private.  Private also cannot be applied to
  // fields or methods yet.

}

module AnotherModule {
  var a = false;
}

module ThirdModule {
  var b = -13.0;
}


module Conflict {
  /* This parenthesis-less function shares a name with a symbol in modToUse. */
  proc bar {
    writeln("In Conflict.bar");
    return 5;
  }

  var other = 5.0 + 3i;

  var another = false;
}

module MainModule {
  proc main() {
    writeln("Access from outside a module");

    /* If a module is not the main module for a program, it is desirable for its
       contents to be accessible to external modules.  There are several
       strategies for accomplishing this:

       First, a symbol can be referenced explicitly - this is done using the
       module name and a separating '.' as a prefix to the name of the symbol
       desired.
    */
    var thriceFoo = 3 * modToUse.foo; // should be 36
    writeln(thriceFoo);


    {
      /* If many of the module's symbols are desired, or the same symbol is
         desired multiple times, then it is best to utilize what is known as a
         "use statement".
      */
      use modToUse;

      /* Use statements can be inserted at any lexical scope that contains
         executable code.

         A use statement makes all of the module's visible symbols available to
         the scope which contains the use statement.  These symbols may then be
         accessed without the module name prefix.

         In this case, bazBarFoo should store the result of calling modToUse.baz
         on modToUse.bar and modToUse.foo, which is in this case '28'.
      */
      var bazBarFoo = baz(bar, foo);
      writeln(bazBarFoo);
    }



    /* Since the following line doesn't live within a scope that contains a
       'use' of 'modToUse', it would generate an error if uncommented.  This is
       because 'foo' cannot be directly referenced, and is not qualified with a
       module name.
    */
    // var twiceFoo = 2 * foo;



    {
      var bazBarFoo = baz(bar, foo);

      /* Use statements apply to the entire scope in which they are defined.
         Even if the use statement occurs after code which would directly refer
         to its symbols, these references are still valid.

         Thus, as in an earlier example, bazBarFoo should store the result of
         calling modToUse.baz on modToUse.bar and modToUse.foo, which is in this
         case '28'.
      */
      use modToUse;

      writeln(bazBarFoo);
    }


    {
      /* The symbols provided by a use statement are only considered when the
         name in question cannot be resolved directly within the local scope.
         Thus, if another bar were defined here, and an access was attempted,
         the compiler would find the bar at this scope, rather than
         modToUse.bar.
      */
      var bar = 4.0;

      use modToUse;

      writeln(bar);
      // Will output the value of the bar defined in scope (which is '4.0'),
      // rather than the value of modToUse.bar (which is '2')
    }


    var bar = false;
    {
      /* If a symbol cannot be resolved directly within the local scope, then
         the symbols provided by a use statement are considered before the
         symbols defined outside of the scope where the use statement applies.
         Thus, if another bar were defined outside of these curly braces, and an
         access was attempted, the compiler would find the bar from modToUse,
         rather than the outer bar.
      */

      use modToUse;
      writeln(bar);
      // Will output the value of modToUse.bar (which is '2'), rather than the
      // value of the bar defined outside of this scope (which is 'false')
    }


    {
      /* Multiple modules may be used in the same use statement */
      use modToUse, AnotherModule, ThirdModule;

      if (a || b < 0) {
        // Refers to AnotherModule.a (which is 'false') and ThirdModule.b (which
        // is '-13.0')
        writeln(foo); // Refers to modToUse.foo
      } else {
        writeln(bar); // Refers to modToUse.bar
      } // Will output modToUse.foo (which is '12')
    }


    {
      /* Equivalently, a scope may contain multiple use statements */
      use modToUse;
      use AnotherModule, ThirdModule;

      writeln(a && foo > 15);
      // outputs false (because AnotherModule.a is 'false' and modToUse.foo is
      // '12')
    }


    {
      /* In either case, the modules used in this way are considered at the same
         scope.  This means that if two modules each define a symbol with the
         same name, and both modules are used at the same scope, attempts to
         access a symbol by that name will result in a naming conflict:
      */
      use modToUse, Conflict;

      writeln(foo); // Outputs modToUse.foo ('12')
      /* The following line would fail because both modToUse and Conflict define
         a symbol named bar:
      */
      // writeln(bar);
      writeln(other); // Outputs Conflict.other ('5.0 + 3.0i')
    }

    writeln();
    writeln("Limiting a use");


    {
      /* To get around such conflicts, there are multiple strategies.  If only a
         small number of symbols are desired from a particular module, you can
         specify the symbols to bring in via an 'only' list.

         Here, because of the 'only' clause in the 'use' of Conflict, Conflict's
         'bar' is not directly accessible here.
      */
      use modToUse;
      use Conflict only other, another;

      writeln(foo); // Outputs modToUse.foo ('12')
      writeln(bar); // Outputs modToUse.bar ('2')
      writeln(other); // Outputs Conflict.other ('5.0 + 3.0i')
    }


    {
      /* If every symbol other than the one which causes a conflict is desired,
         you can specify the symbols to exclude via an 'except' list.
      */
      use Conflict;
      use modToUse except bar;

      writeln(foo); // Outputs modToUse.foo ('12')
      writeln(bar); // Outputs '5' after output in Conflict.bar function
      writeln(other); // Outputs Conflict.other ('5.0 + 3.0i')
    }


    {
      /* If both symbols which conflict are desired, or if the use causes
         symbols to be shadowed which are necessary, you can choose to rename a
         symbol when including it via the 'as' keyword, so long as the new name
         does not cause any conflicts with other included symbols.
      */
      use modToUse;
      use Conflict only bar as boop;
      writeln(bar); // Outputs modToUse.bar ('2')
      writeln(boop); // Outputs '5' after output in Conflict.bar function
    }

    writeln();
    writeln("Application to enums");

    {
      /* 'Use' statements can also be called on enums.  Normally to access one
         of an enum's constants, you must provide a prefix of the enum name.
         With a 'use' of that enum, such a prefix is no longer necessary.
      */

      enum color {red, blue, yellow};

      // Normally you must use the enum name as a prefix
      var aColor = color.blue;
      writeln(aColor);

      use color;

      // The use statement allows you to access an enum's symbols without the
      // prefix
      var anotherColor = yellow; // color.yellow
      writeln(anotherColor);

      // All of the above rules for 'use' statements also apply to 'use's of
      // enums
    }

    writeln();
    writeln("Accessing modules from other files");

    {
      /* Modules that live outside of the file sometimes have special rules for
         how to access them.  If the module you wish to access has the same name
         as the file in which it lives, and this file is in the same directory
         as your program, no additional steps are necessary.
      */

      use modulesHelper;

      writeln(someVar); // Should be 19
    }


    {
      /* When the module you wish to access is not named after the file in which
         it lives, you must name the file as part of the compilation step:

         chpl modules.chpl modulesHelper2.chpl
      */

      use anotherHelper;

      writeln(someFunc()); // Should be 23

      /* Note, the above will only compile if all the code after this closing
         brace until the end of the main() function is removed or commented out.
         A summary compilation line will be provided at the end
      */
    }


    {
      /* If the helper module also defines a main() function, or this module
         does not, then you must specify on the command line at compilation time
         which module should be the main module for the program, using the
         --main-module flag:

         chpl modules.chpl modulesHelper3.chpl --main-module MainModule
      */

      use helperWithMain;

      writeln(someVar); // Should be 19

      /* Note, the above will only compile if all the code after this closing
         brace until the end of the main() function is removed or commented out,
         as well as the code for accessing anotherHelper.  A summary compilation
         line will be provided at the end
      */
    }


    {
      /* If the module you wish to use lives in a different directory, you must
         specify the directory where it lives as part of compilation using the
         -M flag.  The -M flag can take a relative or exact path.

         chpl modules.chpl -M modulesPrimerDir/
      */

      use helperInAnotherDir;
      writeln(someFunc()); // Should be 23

      /* Note, the above will only compile if all the code for accessing
         anotherHelper and helperWithMain is removed or commented out.  A
         summary compilation line will be provided at the end
      */
    }

    {
      /* If the module you wish to use is one of the Chapel provided library
         modules (living in $CHPL_HOME/modules/), then merely using the module
         is sufficient for the program to compile
      */

      use IO;
      writeln(iomode.r);
    }

    /* To compile all the examples in this file, use the command line:

       chpl modules.chpl modulesHelper2.chpl modulesHelper3.chpl --main-module MainModule -M modulesPrimerDir/
    */
  }
}

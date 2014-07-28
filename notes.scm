Motivation: want to use the relational interpreter to perform program
synthesis.  Want to be able to do things like partially specify
'append', give an example call to 'append' using lists containing
eigen variables, and have the relational interpreter fill in the
missing code in 'append'.  Alas, the relational interpreter tends
to "cheat" by generating overly-specific code that is tailored to that
specific example of input/output values.  For example, consider this
test from 'more-schemelyer-relational-interpreter/interp-tests.scm'


;; this failing test shows why we should ideally find the smallest
;; program that satisfies the example, rather than letting miniKanre
;; do the least amount of work to find a solution.
(test "append-6c"
  (run 1 (append-body)
    (fresh (?)
      (eigen (a b c d e)
        (== `(lambda (l s)
               (if (null? l)
                   s
                   (cons (car l) ,?)))
            append-body)
        (evalo
         `(letrec ((append ,append-body))
            (append (quote (,a ,b)) (quote (,c))))
         (list a b c)))))
  '((lambda (l s)
      (if (null? l)
          s
          (cons (car l) (append (cdr l) s))))))
;; miniKanren generates this overly-specific answer:
;;
;; ((lambda (l s)
;;    (if (null? l)
;;        s
;;        (cons (car l) (list (car (cdr l)) (car s))))))

[seems like we can control, to at least some extent, the size of the
overly-specific code by making the input/output example longer.]

[why not just give multiple input/output examples, to prevent
over-specification?  Because this might just result in even more
overly-specified code (perhaps with a conditional).  (I should verify
this, and come up with a real working example.)  Also, because the
multiple example calls are in a conjunction, picking the wrong program
in the first call seems to result in inefficient generate&test
behavior. (Try to prove this/quantify this.)]

Idea: inspired by the success of the Escher system for program
synthesis, try ensuring that we always synthesize the smallest program
that performs the desired function (based on input/output examples, or
whatever).

First approach: create a term-sizeo relation, that generates all terms
of a certain size.  Then, feed the generated terms into the relational
interpreter, as the first (expression) argument.  Actually, this is a
little subtle, since some definitions of term-sizeo may diverge.  [I
should create a definition that shows this--I suspect any term-sizeo
that only takes one term-size argument, and which includes terms like
'cons' that have mutual recursive calls, will suffer from this
problem.  But maybe I was just being dumb.  If nothing else, need to
make sure changes in term size don't "skip" over the base case, allow
the "smaller" term to be larger than the "larger" term, or whatever.]

Here is a (partial) definition of term-sizeo that uses Peano
representation of numerals to allow for non-recursive definiton of
sub1.  This definition seems to work well.  [I didn't include
application, 'list', or 'letrec' in this term-sizeo, since each of
these forms is or arbitrary length, and I didn't want to mess with
recursive helpers.]  [I should define the equivalent version for CBV
LC + quote + cons (or perhaps 'list'), so I can handle quines.]

; initial s-start = total term size
; initial s-left = '(z)
(define term-sizeo
  (lambda (t s-start s-left)
    (fresh ()
      (conde
        [(symbolo t)
         (== `(s . ,s-left) s-start)]
        [(fresh (datum)
           (== `(quote ,datum) t)
           (== `(s . ,s-left) s-start))]
        [(fresh (x* body s-start-1)
           (== `(lambda ,x* ,body) t)
           (== `(s . ,s-start-1) s-start)
           (term-sizeo body s-start-1 s-left))]
        [(fresh (unary-prim-op e s-start-1)
           (== `(,unary-prim-op ,e) t)
           (== `(s . ,s-start-1) s-start)
           (term-sizeo e s-start-1 s-left)
           ;; for best performance, the conde should come after the
           ;; recursive call
           (conde
             [(== 'null? unary-prim-op)]
             [(== 'car unary-prim-op)]
             [(== 'cdr unary-prim-op)]))]
        [(fresh (e1 e2 s-start-1 s-left^)
           (== `(cons ,e1 ,e2) t)
           (== `(s . ,s-start-1) s-start)
           (term-sizeo e1 s-start-1 s-left^)
           (term-sizeo e2 s-left^ s-left))]
        [(fresh (e1 e2 e3 s-start-1 s-left^ s-left^^)
           (== `(if ,e1 ,e2 ,e3) t)
           (== `(s . ,s-start-1) s-start)
           (term-sizeo e1 s-start-1 s-left^)
           (term-sizeo e2 s-left^ s-left^^)
           (term-sizeo e3 s-left^^ s-left))]))))

> (run* (q) (term-sizeo q '(s s s z) '(z)))
(((lambda _.0 (lambda _.1 _.2)) (sym _.2))
  (lambda _.0 (lambda _.1 '_.2))
  ((null? (lambda _.0 _.1)) (sym _.1))
  ((lambda _.0 (null? _.1)) (sym _.1))
  ((car (lambda _.0 _.1)) (sym _.1))
  ((cons _.0 _.1) (sym _.0 _.1))
  ((cdr (lambda _.0 _.1)) (sym _.1))
  ((lambda _.0 (car _.1)) (sym _.1))
  ((lambda _.0 (cdr _.1)) (sym _.1))
  (null? (lambda _.0 '_.1)) (car (lambda _.0 '_.1))
  (lambda _.0 (null? '_.1)) (cdr (lambda _.0 '_.1))
  ((cons _.0 '_.1) (sym _.0)) (lambda _.0 (car '_.1))
  (lambda _.0 (cdr '_.1)) ((cons '_.0 _.1) (sym _.1))
  ((null? (null? _.0)) (sym _.0))
  ((car (null? _.0)) (sym _.0))
  ((cdr (null? _.0)) (sym _.0))
  ((null? (car _.0)) (sym _.0)) ((car (car _.0)) (sym _.0))
  ((cdr (car _.0)) (sym _.0)) ((null? (cdr _.0)) (sym _.0))
  (cons '_.0 '_.1) ((car (cdr _.0)) (sym _.0))
  ((cdr (cdr _.0)) (sym _.0)) (null? (null? '_.0))
  (car (null? '_.0)) (cdr (null? '_.0)) (null? (car '_.0))
  (car (car '_.0)) (cdr (car '_.0)) (null? (cdr '_.0))
  (car (cdr '_.0)) (cdr (cdr '_.0)))	   

This approach seems to work, but generates useless programs like

 ((cons (lambda _.0 (car _.1)) _.2) (sym _.1 _.2))

Also, this seems to force a 'generate and test' approach.


Idea: add s-start and s-left to eval-expo.  Then have evalo bump up
the program size in a loop?  This should guarantee I get the smallest
programs first, right?  (Perhaps modulo interleaving in the search.)
This would also allow the interpreter to fail fast.  And would let us
do things like prove that there exists no programs of size N that
do...whatever.

Another benefit of tracking the term size in the interpreter, rather
than as a separate relation: can let the interpreter code handle
shadowing of primitives.

Start with the relational interpreter for CBV LC + quote + cons.  See
what affect keeping track of the term size has on performance for
generating quines/twines/thrines.  If that seems okay, add term size
to interpreter capable of handling 'append', for example.














> (load "quines-interp-without-size-tests.scm")
Testing "quine-1"
running stats for (run 1 (q) (evalo q q)):
    no collections
    13 ms elapsed cpu time, including 0 ms collecting
    13 ms elapsed real time, including 0 ms collecting
    2289696 bytes allocated
Testing "twine-1"
running stats for (run 1 (out) (fresh (p q) (== (list p q) out) (=/= p q) (evalo p q) (evalo q p))):
    3 collections
    236 ms elapsed cpu time, including 3 ms collecting
    237 ms elapsed real time, including 3 ms collecting
    24378912 bytes allocated
Testing "thrine-1"
running stats for (run 1 (out) (fresh (p q r) (== (list p q r) out) (=/= p q) (=/= p r) (=/= q r) (evalo p q) (evalo q r) (evalo r p))):
    16 collections
    1955 ms elapsed cpu time, including 50 ms collecting
    1956 ms elapsed real time, including 50 ms collecting
    128783408 bytes allocated


Using cons instead of list really slows things down!  Was too impatient to let thrines finish.

> (load "quines-interp-cons-without-size-tests.scm")
Testing "quine-1"
running stats for (run 1 (q) (evalo q q)):
    2 collections
    128 ms elapsed cpu time, including 3 ms collecting
    128 ms elapsed real time, including 3 ms collecting
    17331744 bytes allocated
Testing "twine-1"
running stats for (run 1 (out) (fresh (p q) (== (list p q) out) (=/= p q) (evalo p q) (evalo q p))):
    47 collections
    5221 ms elapsed cpu time, including 277 ms collecting
    5222 ms elapsed real time, including 278 ms collecting
    395138864 bytes allocated


Keeping track of the term size doesn't seem to slow down quine/twine generation too much, at least when the start-size is left fresh.

> (load "quines-interp-cons-with-size-tests.scm")
Testing "quine-1"
running stats for (run 1 (out) (fresh (exp start) (== (list exp start) out) (evalo exp exp start))):
    3 collections
    181 ms elapsed cpu time, including 4 ms collecting
    182 ms elapsed real time, including 4 ms collecting
    20824160 bytes allocated
Testing "twine-1"
running stats for (run 1 (out) (fresh (p q p-start q-start) (== (list p q p-start q-start) out) (=/= p q) (evalo p q p-start) (evalo q p q-start))):
    57 collections
    7610 ms elapsed cpu time, including 386 ms collecting
    7612 ms elapsed real time, including 387 ms collecting
    481487552 bytes allocated






!!! Hmm.  Lambda makes this interesting!  Normally I wouldn't recur
into the body of the lambda until there was an application.  I wonder
if a type inferencer would be a better fit for keeping track of term
size.

!!! A ha!  Tried recurring into the lambda body:

(eval-expo body `((,x . ,?a) . ,env) ?val size-start-1 size-left)

where ?a and ?val are fresh variables.  Big mistake--slowed down quine
generation so much that even generating the first quine didn't return
after several seconds, even with the input/output sizes to the
eval-expo call left fresh.  Buuuut...if I just make the size of a
lambda term '1', and don't recur into the body, the application clause
takes case of the term size when there is an actual application.  This
approach slows down quine/twine generation when input size is left
fresh, but only by 70% or so (vs. orders of magnitude when recurring
into the body of a lambda).

Metaphoriacally, this approach seems to make sense.  Quote and lambda
and variable reference are all trivial (can't diverge), and therefore
all have size one.

??? Does using the term size arguments make the interpreter's
performance less sensitive to reordering conde clauses?

??? What is the relationship between adding the term size (and
iterating it in a loop) and IDDFS?  Are these somehow equivalent?  Not
exactly, since the counter only applies to term size, and no other
part of the search.

??? Should I really treat all quoted datum as being the same size?
This feels right to me, but I'm not certain.

??? What effect on performance would there be from moving unifications
related to term size before unifications of 'exp' and 'val'?

??? Does it make sense to hoist size-related unifications in the
interpreter, perhaps at the cost of introducing additional conde's?








Size-based proofs in 'quines-interp-cons-with-size-tests.scm':

;; proof!
;;
;; prove there is no quine of size 11
(test "quine-1-incorrect-tiny-size-specified-11"
  (time
    (run* (out)
      (fresh (exp start)
        (== (list exp start) out)
        (== '(s s s s s s s s s s s z) start)
        (evalo exp exp start))))
  '())

;; proof!
;;
;; (takes a little over 2 minutes to prove there is only one quine of
;; size 12)
;;
;; could parallelize these queries; would this help?
;;
;; are we benefiting from pruning/fail-fast behavior, in constrast to
;; naive generate & test?  I suspect so.  Prove it!
(test "quine-1-all-quines-size-12"
  (time
    (run* (out)
      (fresh (exp start)
        (== (list exp start) out)
        (== '(s s s s s s s s s s s s z) start)
        (evalo exp exp start))))
  '(((((lambda (_.0) (cons _.0 (cons (cons 'quote (cons _.0 '())) '())))
       '(lambda (_.0) (cons _.0 (cons (cons 'quote (cons _.0 '())) '()))))
      (s s s s s s s s s s s s z))
     (=/= ((_.0 closure)) ((_.0 cons)) ((_.0 quote))) (sym _.0))))






[TODO
 
* add term size to 'list'-based interpreter, and compare performance
to 'cons'-based interprter for quine generation

* add term size to interpreter capable of expressing 'append' in
Scheme.  Try program synthesis, with input/output example(s).  Does
this approach generate the smallest program?  Is the smallest program
the correct, recursive definition?  Or code that is special-cased and
overly specific?

* come up with better variable names!

* try parallelizing the queries.  what sort of speedup can I get?

* compare performance between separate term-sizeo + eval-expo
vs. eval-expo with integrated term size.  Are the separate relations
less performant?  Do they show more generate&test behavior?]







I wrote a recursive helper using 'conde' that increments the term size
by one, then calls evalo, and repeats in a loop
[quines-interp-cons-with-size/evalo.scm]:

(define eval-increment-sizeo
  (lambda (exp val size)
    (let loop ((sz '(z)))
      (conde
        ((== sz size) (evalo exp val sz))
        ((loop (cons 's sz)))))))

As I suspected, this definition doesn't generate terms in
monotonically increasing size, as can be seen by this test
[quines-interp-cons-with-size/quines-interp-cons-with-size-tests.scm]:

;; shows that the generated terms do not increase in size
;; monotonically when using the conde-based 'eval-increment-sizeo'
(test "eval-increment-sizeo term  I love you 2"
  ;; conde-based loop  
  (map peano->arabic
       (run 100 (size)
         (fresh (term)
           (eval-increment-sizeo term '(I love you) size))))
  '(1 3 4 4 4 5 6 6 6 6 6 6 6 6 6 6 6 6 7 6 7 7 6 7 7 6 8 7 7 7 7 7 7 8 7 8 8 7 7 8 7 8 7 7 7 8 8 7 7 8 8 7 7 7 7 8 9 8 7 7 8 8 8 7 8 9 7 7 7 8 7 7 7 8 8 8 7 7 7 8 8 7 8 9 9 9 8 9 9 9 8 9 8 9 9 9 9 9 9 9))

We can use 'conda' to guarantee we find the smallest answers:

[quines-interp-cons-with-size/evalo.scm]

;; uses impure control construct to find terms of the smallest size
;; that satisfies the query
(define eval-find-smallesto
  (lambda (exp val size)
    (let loop ((sz '(z)))
      (conda
        ((fresh () (== sz size) (evalo exp val sz)))
        ((loop (cons 's sz)))))))

[quines-interp-cons-with-size/quines-interp-cons-with-size-tests.scm]

;; Finds one quine of the smallest possible term size (there could be
;; others of that size, although it turns out there are not, as can be
;; proved by changing the run 1 to a run*)
;;
;; Testing "eval-find-smallesto term   quine 1"
;; running stats for (run 1 (q) (fresh (term size) (== (list term size) q) (eval-find-smallesto term term size))):
;;     634 collections
;;     50227 ms elapsed cpu time, including 1265 ms collecting
;;     50262 ms elapsed real time, including 1269 ms collecting
;;     5305968784 bytes allocated
(test "eval-find-smallesto term   quine 1"
  ;; conda-based loop
  (time (run 1 (q)
          (fresh (term size)
            (== (list term size) q)
            (eval-find-smallesto term term size))))
  '(((((lambda (_.0) (cons _.0 (cons (cons 'quote (cons _.0 '())) '())))
       '(lambda (_.0) (cons _.0 (cons (cons 'quote (cons _.0 '())) '()))))
      (s s s s s s s s s s s s z))
     (=/= ((_.0 closure)) ((_.0 cons)) ((_.0 quote)))
     (sym _.0))))

In fact, conda lets us find *all* the answers of that smallest term
size, and no answers of any larger term size, by using run*
[quines-interp-cons-with-size/quines-interp-cons-with-size-tests.scm]:

;; Finds the smallest quine, and proves it is the only quine of that size or smaller.
;;
;; Testing "eval-find-smallesto term   all smallest quines 1"
;; running stats for (run* (q) (fresh (term size) (== (list term size) q) (eval-find-smallesto term term size))):
;;     2257 collections
;;     202225 ms elapsed cpu time, including 5448 ms collecting
;;     202328 ms elapsed real time, including 5459 ms collecting
;;     18913076288 bytes allocated
(test "eval-find-smallesto term   all smallest quines 1"
  ;; conda-based loop
  (time (run* (q)
          (fresh (term size)
            (== (list term size) q)
            (eval-find-smallesto term term size))))
  '(((((lambda (_.0) (cons _.0 (cons (cons 'quote (cons _.0 '())) '())))
       '(lambda (_.0) (cons _.0 (cons (cons 'quote (cons _.0 '())) '()))))
      (s s s s s s s s s s s s z))
     (=/= ((_.0 closure)) ((_.0 cons)) ((_.0 quote)))
     (sym _.0))))

We can use 'eval-find-smallesto' to find all of the smallest
satisfying terms of a given size or larger
[quines-interp-cons-with-size/quines-interp-cons-with-size-tests.scm]:

(test "eval-find-smallesto  find all of the smallest '(I love you)-building terms that are at least size 2 or greater"
  ;; conda-based loop
  (run* (q)
    (fresh (term size rest)
      (== `(s s . ,rest) size)
      (eval-find-smallesto term '(I love you) size)
      (== (list term size) q)))
  '(((cons 'I '(love you))
     (s s s z))))

(test "eval-find-smallesto  find all of the smallest '(I love you)-building terms that are at least size 4 or greater"
  ;; conda-based loop
  (run* (q)
    (fresh (term size rest)
      (== `(s s s s . ,rest) size)
      (eval-find-smallesto term '(I love you) size)
      (== (list term size) q)))
  '(((((lambda (_.0) '(I love you)) '_.1)
      (s s s s z))
     (=/= ((_.0 closure)) ((_.0 quote))) (sym _.0)
     (absento (closure _.1)))
    ((((lambda (_.0) _.0) '(I love you))
      (s s s s z))
     (=/= ((_.0 closure))) (sym _.0))
    ((((lambda (_.0) '(I love you)) (lambda (_.1) _.2))
      (s s s s z))
     (=/= ((_.0 closure)) ((_.0 quote)) ((_.1 closure)))
     (sym _.0 _.1) (absento (closure _.2)))))

If we were to replace conda with condu in the definition of
'eval-find-smallesto', run* and run1 would always behave identically.
[should try this and verify]




Observation: finding the first quine is fastest when the term size is
left unspecified through just a call to evalo with a
fresh variable for term size:

;; Testing "quine-1"
;; running stats for (run 1 (out) (fresh (exp start) (== (list exp start) out) (evalo exp exp start))):
;;     2 collections
;;     210 ms elapsed cpu time, including 4 ms collecting
;;     210 ms elapsed real time, including 4 ms collecting
;;     20824128 bytes allocated

Much slower (20x slower) is generating the quine using the 'conde'-based 'eval-increment-sizeo':

;; Testing "quine-increment-size-1"
;; running stats for (run 1 (out) (fresh (term size) (eval-increment-sizeo term term size) (== (list term size) out))):
;;     61 collections
;;     4502 ms elapsed cpu time, including 253 ms collecting
;;     4504 ms elapsed real time, including 253 ms collecting
;;     510730928 bytes allocated

Much slower still (another 10x slower) is generating the quine using
the 'conda'-based 'eval-find-smallesto', which guarantees that there
is no smaller answer:

;; Testing "eval-find-smallesto term   quine 1"
;; running stats for (run 1 (q) (fresh (term size) (== (list term size) q) (eval-find-smallesto term term size))):
;;     634 collections
;;     50227 ms elapsed cpu time, including 1265 ms collecting
;;     50262 ms elapsed real time, including 1269 ms collecting
;;     5305968784 bytes allocated

How is this behavior related to generate&test?  Why is it so slow to
rule out all smaller term sizes?  Can this be sped up?  These data
seem to raise more questions than they answer.




Directory structures:

more-schemelyer-relational-interpreter
--------------------------------------
version of the relational interpreter with letrec, multiple argument lambda, etc, without term size.  Test 'append-6c' shows why we are interested in generating the smallest program when performing program synthesis.

quines-interp-cons-with-size
-----------------------------
quine-generating interpreter, using cons instead of list, and which keeps track of term size

quines-interp-cons-without-size
-----------------------------
quine-generating interpreter, using cons instead of list, which doesn't keeps track of term size

quines-interp-with-size
-----------------------------
quine-generating interpreter, using list instead of cons, and which keeps track of term size

quines-interp-without-size
-----------------------------
quine-generating interpreter, using list instead of cons, which doesn't keep track of term size

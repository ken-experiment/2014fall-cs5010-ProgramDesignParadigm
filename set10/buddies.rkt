;; buddies.rkt
;; Set10-Question 2
;; Zoltan Wang, Pankaj Tripathi

;; Use (run 0.25) to run the program
;; Where rate is a positive number and speed is a positive integer
;; Toys in world of canvas that is 400x500 pixels with circle of radius 10 in
;; outline mode as target 
;; toys in world are
;; 1) child types "s", a new square-shaped(30*30) toy pops up on canvas. These
;; square toys can be dragged on canvas and they can be made buddies with other
;; square
;; 3)target will have property of smooth drag

#lang racket

(require rackunit)
(require "extras.rkt")
(require 2htdp/universe)   
(require 2htdp/image)

(provide World%)
(provide SquareToy%)
(provide make-world)
(provide run)
(provide StatefulWorld<%>)
(provide StatefulToy<%>)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;                                CONSTANTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define ZERO 0)
(define TARGET-RADIUS 10)

(define SQUARE-LENGTH 30)
(define HALF-SQUARE-LENGTH (/ SQUARE-LENGTH 2))

(define CANVAS-WIDTH 400)
(define CANVAS-HEIGHT 500)
(define HALF-CANVAS-WIDTH (/ CANVAS-WIDTH 2))
(define HALF-CANVAS-HEIGHT (/ CANVAS-HEIGHT 2))

(define S "s")

(define BLACK "black")
(define ORANGE "orange")
(define GREEN "green")
(define RED "red")

(define OUTLINE "outline")

(define BUTTON-DOWN "button-down")
(define DRAG "drag")
(define BUTTON-UP "button-up")

(define EMPTY-CANVAS (empty-scene CANVAS-WIDTH CANVAS-HEIGHT))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;                              INTERFACES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define StatefulWorld<%>
  (interface ()

    ;; -> Void
    ;; EFFECT: updates this StatefulWorld<%> to the 
    ;;         state that it should be in after a tick.
    on-tick                             

    ;; Integer Integer MouseEvent -> Void
    ;; EFFECT: updates this StatefulWorld<%> to the 
    ;;         state that it should be in after the given MouseEvent
    on-mouse

    ;; KeyEvent -> Void
    ;; EFFECT: updates this StatefulWorld<%> to the 
    ;;         state that it should be in after the given KeyEvent
    on-key

    ;; -> Scene
    ;; Returns a Scene depicting this StatefulWorld<%> on it.
    on-draw 
    
    ;; -> Integer
    ;; RETURN: the x and y coordinates of the target
    target-x
    target-y

    ;; -> Boolean
    ;; Is the target selected?
    target-selected?

    ;; -> ColorString
    ;; color of the target
    target-color
    
    ;; -> ListOfStatefulToy<%>
    get-toys

))

;-------------------------------------------------------------------------------

(define StatefulToy<%> 
  (interface ()
    
    ;; Integer Integer MouseEvent -> Void
    ;; EFFECT: updates this StatefulToy<%> to the 
    ;;         state that it should be in after the given MouseEvent
    on-mouse

    ;; Scene -> Scene
    ;; Returns a Scene like the given one, but with this  
    ;; StatefulToy<%> drawn on it.
    add-to-scene

    ;; -> Int
    toy-x
    toy-y

    ;; -> ColorString
    ;; returns the current color of this StatefulToy<%>
    toy-color

    ;; -> Boolean
    ;; Is this StatefulToy<%> selected?
    toy-selected?

    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;                           DATA DEFINITION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; ColorString is one of
;; -- "RED"   
;; -- "GREEN" 
;; -- "BLACK"   
;; -- "ORANGE"
;;TEMPLATE
;; colorstring-fn:  ColorString -> ??
;; (define (colorstring-fn color)
;;  (cond
;;    [(string=? color RED) ...]
;;    [(string=? color GREEN) ...]
;;    [(string=? color BLACK) ...]
;;    [(string=? color ORANGE) ...]))


;; A ListOfStatefulToy<%>(LOT) is one of
;; -- (empty)                      -- it is empty with no toys
;; -- (cons StatefulToy<%> ListOfStatefulToy<%>)   
;;                                 -- first element is a StatefulToy<%>  
;;                                    and second element is ListOfStatefulToy<%>
;; TEMPLATE:
;; lot-fn : LOT -> ??
;; (define (lot-fn lot)
;;   (cond
;;    [(empty? lot)...]
;;    [else (...(first lot))
;;              (lot-fn (rest lot)))]))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                               CLASS WORLD
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; World%     -- a class that satisfies the StatefulWorld<%> interface.
;; A World is a (new World% [target Target] [toys ListOfStatefulToy<%>]  
;; INTERP: It represents a world, which has a Target and list of toys 

(define World%
  (class* object% (StatefulWorld<%>)         
    (init-field 
     [target (new Target%)]   ;; it is a circle of radius 10
     [toys empty])            ;; toys can include number of squares which can  
                              ;; be dragged
    
    (super-new)
    
    ;; on-tick: -> Void
    ;; EFFECT: updates this StatefulWorld<%> to the 
    ;;         state that it should be in after a tick.
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (on-tick) this)
    
    ;; on-mouse: Integer Integer MouseEvent -> Void
    ;; GIVEN: x and y coordinates of mouse pointer and mousevent
    ;; EFFECT: updates this StatefulWorld<%> to the 
    ;;         state that it should be in after the given MouseEvent
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: High Order Function Composition
    (define/public (on-mouse mouse-x mouse-y evt)
      (send target on-mouse mouse-x mouse-y evt)
      (for-each 
       ;; StatefulToy<%> -> Void
       ;; GIVEN: a toy which is a square
       ;; EFFECT: a toy like given that should respond to valid mouse events 
       (lambda (toy) (send toy on-mouse mouse-x mouse-y evt))
       toys))
    
    ;; on-key: KeyEvent -> Void
    ;; GIVEN: A KeyEvent
    ;; EFFECT: updates this StatefulWorld<%> to the 
    ;;         state that it should be in after the given KeyEvent
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Cases on kev: KeyEvent
    (define/public (on-key evt)
      (cond
        [(key=? evt S)(on-key-event-s)]
        [else this]))
    
    ;; on-key-event-s: -> Void
    ;; EFFECT: updates this StatefulWorld<%> to the 
    ;;         state that it should be in after the given KeyEvent 
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: High Order Function Composition
    (define/public (on-key-event-s)
      (local
           ((define tgt-x (target-x))
            (define tgt-y (target-y)))
           (begin
             (set! toys (cons (new SquareToy% [x tgt-x] [y tgt-y]) toys))
             (for-each
              ;; StatefulToy<%> -> Void
              ;; GIVEN: a toy which is a square
              ;; EFFECT: a toy like given that should after adding toys
              ;; to it arguement
              (lambda (toy) (send toy set-toys toys)) 
              toys))))
    
    ;; on-draw: -> Scene
    ;; RETURNS: a Scene depicting this StatefulWorld<%> on it.
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: High Order Function Composition
    (define/public (on-draw)
      (local
        ((define bg (send target add-to-scene EMPTY-CANVAS)))
        (foldr 
         ;; StatefulToy<%> Scene ->Scene
         ;; GIVEN: a toy and a scene
         ;; RETURNS: a scene after toy is painted on it
         (lambda (toy scene) (send toy add-to-scene scene))
         bg 
         toys)))
    
    ;; target-x: -> Integer
    ;; target-y: -> Integer
    ;; RETURNS: the x and y coordinates of the target
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (target-x) (send target toy-x))
    (define/public (target-y) (send target toy-y))
    
    ;; target-selected?: -> Boolean
    ;; RETURNS: Is the target selected?
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (target-selected?) (send target toy-selected?))
    
    ;; target-color:  -> ColorString
    ;; RETURNS: color of the target
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (target-color) (send target toy-color))
    
    ;; get-toys: -> ListOfStatefulToy<%>
    ;; RETURNS: all toys in the world
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (get-toys) toys)
    
    ;; Methods defined for testing purpose
    
    ;; world-target: -> StatefulToy<%>
    ;; RETURNS: a Target% object which implements StatefulToy<%> interface
    ;; EXAMPLES: This method returns the target when called on object of class
    ;;           World%.
    ;; STRATEGY: Function Composition
    (define/public (world-target) target)
    
    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;                              CLASS TARGET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; A Target is a (new Target% [x Integer] [y Integer] [selected? Boolean]
;;                            [color ColorString][mx Integer] [my Integer])
;; INTERP: It represents a Target, which it self is a circle and can be smoothly
;; dragged on the canvas

(define Target%
  (class* object% (StatefulToy<%>)
    (init-field
     [x HALF-CANVAS-WIDTH]  ;; the x position of the target
     [y HALF-CANVAS-HEIGHT] ;; the y position of the target
     [selected? false]      ;; indicate whether the target is selected
     [color BLACK]          ;; indicate color of the target
     [mx ZERO]              ;; the x position of the mouse pointer in the target
     [my ZERO])             ;; the y position of the mouse pointer in the target
    
    (super-new)
    
    ;; on-mouse: Integer Integer MouseEvent -> Void
    ;; GIVEN: x and y coordinates of mouse pointer and mousevent
    ;; EFFECT: updates this Target% to the 
    ;;         state that it should be in after the given MouseEvent
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Cases on evt: MouseEvent
    (define/public (on-mouse mouse-x mouse-y evt)
      (cond
        [(mouse=? evt BUTTON-DOWN) (target-after-button-down mouse-x mouse-y)]
        [(mouse=? evt DRAG) (target-after-drag mouse-x mouse-y)]
        [(mouse=? evt BUTTON-UP) (target-after-button-up mouse-x mouse-y)]
        [else this]))
    
    ;; target-after-button-down : Integer Integer -> Void
    ;; GIVEN: the location of a mouse event
    ;; EFFECT: the target that should follow this one after a button
    ;; down at the given location
    ;; DETAILS:  If the event is within
    ;; the target, returns a target just like this target, except that it is
    ;; selected.  Otherwise returns the target unchanged.
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (target-after-button-down mouse-x mouse-y)
      (if (within? mouse-x mouse-y)
          (begin (set! selected? true)
                 (set! color ORANGE)
                 (set! mx mouse-x)
                 (set! my mouse-y))
          this))
    
    ;; target-after-drag : Integer Integer -> Void
    ;; GIVEN: the location of a mouse event
    ;; EFFECT: the target that should follow this one after a drag at
    ;; the given location 
    ;; DETAILS: if target is selected, move the target to the mouse location,
    ;; otherwise ignore.
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (target-after-drag mouse-x mouse-y)
      (if selected?
          (begin (set! x (+ x (- mouse-x mx)))
                 (set! y (+ y (- mouse-y my)))
                 (set! mx mouse-x)
                 (set! my mouse-y))
          this))
    
    ;; target-after-button-up : -> Void
    ;; EFFECT: the target that should follow this one after a button-up
    ;; DETAILS: button-up unselects all targets
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (target-after-button-up mouse-x mouse-y)
      (set! selected? false)
      (set! color BLACK)
      (set! mx ZERO)
      (set! my ZERO))    
    
    ;; within? : Integer Integer -> Boolean
    ;; GIVEN: a location of mouse pointer on the canvas
    ;; RETURNS: true iff the location is inside this target.
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (within? mouse-x mouse-y)
      (<= (+ (sqr (- x mouse-x)) (sqr (- y mouse-y)))
          (sqr TARGET-RADIUS)))
    
    ;; add-to-scene: Scene -> Scene
    ;; RETURNS: a Scene like the given one, but with this  
    ;; StatefulToy<%> drawn on it.
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (add-to-scene s)
      (local
        ((define IMG (circle TARGET-RADIUS OUTLINE color)))
        (place-image IMG x y s)))
    
    ;; toy-x: -> Integer
    ;; toy-y: -> Integer
    ;; RETURNS: x and y coordinates of the target repectively
    ;; EXAMPLES: See test cases at the end.         
    ;; STRATEGY: Function Composition
    (define/public (toy-x) x)
    (define/public (toy-y) y)
    
    ;; toy-selected?: -> Boolean
    ;; RETURNS: Is the target selected?
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (toy-selected?) selected?)
    
    ;; toy-color: -> ColorString
    ;; RETURNS: the current color of this target
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (toy-color) color)
    
    ;; Methods defined for testing purpose
    
    ;; target-mx: -> Integer
    ;; target-my: -> Integer
    ;; RETURNS: the x and y coordinates of center of the mouse pointer
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (target-mx) mx)
    (define/public (target-my) my)
    
    ;; for-test:testing-case: StatefulToy<%> -> Boolean
    ;; GIVEN: a Target% object implementing StatefulToy<%> interface.
    ;; RETURNS: true if the current calling target object has same values as 
    ;;          obtained when individual functions are called for each field
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (for-test:testing-case obj)
      (and (= x (send obj toy-x))
           (= y (send obj toy-y))
           (equal? color (send obj toy-color))
           (equal? selected? (send obj toy-selected?))
           (= mx (send obj target-mx))
           (= my (send obj target-my))))
    
    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;                            CLASS SQUARETOY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; SquareToy% -- a class that satisfies the StatefulToy<%> interface
;; A SquareToy is a (new SquareToy% [x Integer] [y Integer] 
;;                                  [speed PosInt] [direction Direction]
;;                                  [color ColorString])
;; INTERP: A SquareToy represents a square-shaped toy
(define SquareToy%
  (class* object% (StatefulToy<%>)
    (init-field
     x                 ;; the x position of the toy
     y                 ;; the y position of the toy
     [selected? false] ;; indicate whether the toy is selected
     [color GREEN]     ;; indicate color of the toy
     [buddies empty]   ;; a list of toy which contains this toy's buddies
     [toys empty]      ;; a list of toy passed from world
     [mx ZERO]         ;; the x position of the mouse pointer in the toy
     [my ZERO])        ;; the y position of the mouse pointer in the toy
    
    (super-new)
    
    ;; on-mouse: Integer Integer MouseEvent -> Void
    ;; GIVEN: x and y coordinates of mouse pointer and mousevent
    ;; EFFECT: updates this SquareToy% to the 
    ;;         state that it should be in after the given MouseEvent
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Cases on evt: MouseEvent
    (define/public (on-mouse mouse-x mouse-y evt)
      (cond
        [(mouse=? evt BUTTON-DOWN) (toy-after-button-down mouse-x mouse-y)]
        [(mouse=? evt DRAG) (toy-after-drag mouse-x mouse-y)]
        [(mouse=? evt BUTTON-UP) (toy-after-button-up mouse-x mouse-y)]
        [else this]))
    
    ;; toy-after-button-down : Integer Integer -> Void
    ;; GIVEN: the location of a mouse event
    ;; EFFECT: the toy that should follow this one after a button
    ;; down at the given location
    ;; DETAILS:  If the event is within
    ;; the toy, returns a toy just like this toy, except that it is
    ;; selected.  Otherwise returns the toy unchanged.
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: High Order Function Composition
    (define/public (toy-after-button-down mouse-x mouse-y)
      (if (within? mouse-x mouse-y)
          (begin
            (set! selected? true)
            (set-color&coord mouse-x mouse-y)
            (for-each 
             ;; StatefulToy<%> -> Void
             ;; GIVEN: a toy
             ;; EFFECT: its color and coordinates of mx/my are set
             (lambda (bud) (send bud set-color&coord mx my)) buddies))
          this))
    
    ;; toy-after-drag : Integer Integer -> Void
    ;; GIVEN: the location of a mouse event
    ;; EFFECT: the toy that should follow this one after a drag at
    ;; the given location 
    ;; DETAILS: if toy is selected, move the toy to the mouse location,
    ;; otherwise ignore.
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: High Order Function Composition
    (define/public (toy-after-drag mouse-x mouse-y)
      (if selected?
          (begin
            (add-buddies&move mouse-x mouse-y)
            (for-each 
             ;; StatefulToy<%> -> Void
             ;; GIVEN: a toy
             ;; EFFECT: add buddy to it and move it
             (lambda (bud) 
               (send bud add-buddies&move mouse-x mouse-y)) 
             buddies))
          this))
   
    ;; add-buddies&move : Integer Integer -> Void
    ;; GIVEN: the location of a mouse event
    ;; EFFECT: the toy moving after adding buddies
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (add-buddies&move mouse-x mouse-y)
      (add-buddies)
      (move mouse-x mouse-y)
      (add-buddies))
    
    ;; move : Integer Integer -> Void
    ;; GIVEN: the location of a mouse event
    ;; EFFECT: the toy after it's moving
    ;; DETAILS: it should move as smoothly dragged
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (move mouse-x mouse-y)      
      (set! x (+ x (- mouse-x mx)))
      (set! y (+ y (- mouse-y my)))
      (set-color&coord mouse-x mouse-y))
    
    ;; add-buddies : -> Void
    ;; EFFECT: the toy after adding buddies to its arguement
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: High Order Function Composition
    (define/public (add-buddies)
      (for-each
       ;; StatefulToy<%> -> Void
       ;; GIVEN: a toy
       ;; EFFECT: according to, whether this toy intersects the current toy, 
       ;; update the current toy's buddies
       (lambda (toy)
         (if (intersect? (send toy toy-x) (send toy toy-y))
             (begin
               (add-buddies-helper toy)
               (send toy add-buddies-helper this))
             this))
       toys))
    
    ;; add-buddies-helper : StatefulToy<%> -> Void
    ;; GIVEN: a toy
    ;; EFFECT: according to the toy's status, set it as the current
    ;; toy's buddy or not
    ;; DETAILS: if it is the current toy, which will always intersect
    ;; itself, or already in the buddies list, we will choose not to
    ;; add it into buddies
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (add-buddies-helper toy)
      (if (not (or (buddies-member? toy) (equal? toy this)))
          (begin
            (set! buddies (cons toy buddies))
            (send toy set-mouse-coordinates mx my))
          this))
     
    ;; toy-after-button-up : -> Void
    ;; EFFECT: the toy that should follow this one after a button-up
    ;; DETAILS: button-up unselects all toys
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (toy-after-button-up mouse-x mouse-y)
      (set! selected? false)
      (set! color GREEN))
    
    ;; buddies-member? : StatefulToy<%> -> Boolean
    ;; GIVEN: a toy
    ;; RETURNS: true iff it is already a member of the current toy's
    ;; buddies
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: High Order Function Composition
    (define/public (buddies-member? toy)
      (ormap 
       ;; StatefulToy<%> -> Boolean
       ;; GIVEN: a toy
       ;; RETURNS: true iff the current toy is equal to the input toy
       (lambda (buddy) (equal? buddy toy)) buddies))

    ;; within? : Integer Integer -> Boolean
    ;; GIVEN: a location of mouse pointer on the canvas
    ;; RETURNS: true iff the location is inside this toy.
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (within? mouse-x mouse-y)
      (and (<= (abs (- x mouse-x)) HALF-SQUARE-LENGTH)
           (<= (abs (- y mouse-y)) HALF-SQUARE-LENGTH)))
    
    ;; intersect? : Integer Integer -> Boolean
    ;; GIVEN: the other toy's x, y coordinates
    ;; RETURNS: true iff that toy intersects the current toy
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (intersect? other-x other-y)
      (and (<= (abs (- x other-x)) SQUARE-LENGTH)
           (<= (abs (- y other-y)) SQUARE-LENGTH)))
    
    ;; set-color&coord : Integer Integer -> Void
    ;; GIVEN: the coordinate to which we want to set this toy's mx/my
    ;; EFFECT: the toy after setting its color and mx/my
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (set-color&coord tgt-mx tgt-my)
      (set-color-red)
      (set-mouse-coordinates tgt-mx tgt-my))
    
    ;; set-color-red : -> Void
    ;; EFFECT: the toy after setting its color red
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (set-color-red)
      (set! color RED))
    
    ;; set-mouse-coordinates : Integer Integer -> Void
    ;; GIVEN: the coordinate to which we want to set this toy's mx/my
    ;; EFFECT: the toy after setting its mx/my
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (set-mouse-coordinates tgt-mx tgt-my)
      (set! mx tgt-mx)
      (set! my tgt-my))
    
    ;; set-toys : LOT -> Void
    ;; GIVEN: a list of toy passed from the world
    ;; EFFECT: the toy after setting its toys as that list of toy
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (set-toys toys-from-world)
      (set! toys toys-from-world))
    
    ;; add-to-scene: Scene -> Scene
    ;; RETURNS: a Scene like the given one, but with this  
    ;; StatefulToy<%> drawn on it.
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (add-to-scene s)
      (place-image (square SQUARE-LENGTH OUTLINE color) x y s))
    
    ;; toy-x: -> Integer
    ;; toy-y: -> Integer
    ;; RETURNS: x and y coordinates of the toy repectively
    ;; EXAMPLES: See test cases at the end.         
    ;; STRATEGY: Function Compositio
    (define/public (toy-x) x)
    (define/public (toy-y) y)
    
    ;; toy-selected?: -> Boolean
    ;; RETURNS: Is the toy selected?
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (toy-selected?) selected?)
    
    ;; toy-color: -> ColorString
    ;; RETURNS: the current color of this toy
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (toy-color) color)
    
    ;; Methods defined for testing purpose
    
    ;; toy-mx: -> Integer
    ;; toy-my: -> Integer
    ;; RETURNS: the x and y coordinates of center of the mouse pointer
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (toy-mx) mx)
    (define/public (toy-my) my)
    
    ;; toy-buddies: -> Integer
    ;; RETURNS: the length of this toy's buddies
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (toy-buddies) (length buddies))
    
    ;; toy-toys: -> Integer
    ;; RETURNS: the length of the list of toy passed from world
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (toy-toys) (length toys))
    
    ;; for-test:testing-case: StatefulToy<%> -> Boolean
    ;; GIVEN: a SquareToy%.
    ;; RETURNS: true if the current calling toy object has same values as 
    ;;          obtained when individual functions are called for each field
    ;; EXAMPLES: See test cases at the end.
    ;; STRATEGY: Function Composition
    (define/public (for-test:testing-case obj)
      (and (= x (send obj toy-x))
           (= y (send obj toy-y))
           (equal? color (send obj toy-color))
           (equal? selected? (send obj toy-selected?))
           (= mx (send obj toy-mx))
           (= my (send obj toy-my))
           (equal? (length buddies) (send obj toy-buddies)) 
           (equal? (length toys) (send obj toy-toys))))
    
    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;                            MAKE-WORLD FUNCTION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; make-world : -> StatefulWorld<%>
;; GIVEN: no arguments
;; RETURNS: A World% with no squares.
;; STRATEGY: Function Composition
(define (make-world)
  (new World%))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;                              RUN FUNCTION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; run : PosNum -> Void
;; GIVEN: a frame rate (in seconds/tick)
;; EFFECT: creates and runs a world that runs at the given rate.
;; RETURNS: the final world.

(define (run rate)
  (big-bang 
   (make-world)
   (on-draw 
    ;; StatefulWorld<%> -> Scene
    ;; GIVEN: a world
    ;; RETURNS: a world drawn on the scene
    (lambda (w) (send w on-draw)))
   (on-tick 
    ;; StatefulWorld<%> -> StatefulWorld<%>
    ;; GIVEN: a world
    ;; RETURNS: a world that should follow after tick
    (lambda (w) (send w on-tick) w) rate)
   (on-key 
    ;; StatefulWorld<%> KeyEvent -> StatefulWorld<%>
    ;; GIVEN: a world and a key event
    ;; RETURNS: a world after a key event
    (lambda (w kev) (send w on-key kev) w))
   (on-mouse 
    ;; StatefulWorld<%> Integer Integer MouseEvent -> StatefulWorld<%>
    ;; GIVEN: a world, mouse location(x,y coordinates) and a mouse
    ;; event
    ;; RETURNS: a world after a mouse event
    (lambda (w x y evt) (send w on-mouse x y evt) w))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;                                  TESTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Test Cases for World%

;; compare-world? : StatefulWorld<%> StatefulWorld<%> ->Boolean
;; GIVEN: two worlds for comparison
;; RETURNS: true iff two worlds are same
;; EXAMPLE: as per test cases
;; STRATEGY: High Order Function Composition

(define (compare-world? world1 world2)
  (and (send (send world1 world-target) for-test:testing-case 
                     (send world2 world-target))
       (andmap
        ; StatefulToy<%> StatefulToy<%> -> Boolean
        ; GIVEN: two toy objects
        ; RETURNS: true iff the two toys are same
        (lambda (t1 t2) (send t1 for-test:testing-case t2))
        (send world1 get-toys)
        (send world2 get-toys))))

(define world1 (new World% [target (new Target% [x 200][y 250]
                                                [selected? false]
                                                [color BLACK]
                                                [mx 0][my 0])]
                           [toys (list (new SquareToy% [x 300][y 150]
                                                       [selected? false]
                                                       [color GREEN]
                                                       [buddies empty]
                                                       [toys empty]
                                                       [mx 0][my 0]))]))

(define world-button-down (new World% [target (new Target% [x 200][y 250]
                                                [selected? false]
                                                [color BLACK]
                                                [mx 0][my 0])]
                           [toys (list (new SquareToy% [x 300][y 150]
                                                       [selected? false]
                                                       [color GREEN]
                                                       [buddies empty]
                                                       [toys empty]
                                                       [mx 0][my 0]))]))

(define world-on-draw
  (place-image (square 30 "outline" "green") 300 150
                            (place-image (circle 10 "outline" BLACK) 
                                         200 250 EMPTY-CANVAS)))

(define empty-world-for-square1 (make-world))
(define empty-world-for-square2 (make-world))

(define world-with-square1 (new World% [target (new Target% [x 200][y 250]
                                                [selected? false]
                                                [color BLACK]
                                                [mx 0][my 0])]
                           [toys (list (new SquareToy% [x 200][y 250]
                                                       [selected? false]
                                                       [color GREEN]
                                                       [buddies empty]
                                                       [toys empty]
                                                       [mx 0][my 0]))]))

(define world-with-square2 (new World% [target (new Target% [x 200][y 250]
                                                [selected? false]
                                                [color BLACK]
                                                [mx 0][my 0])]
                           [toys (list (new SquareToy% [x 200][y 250]
                                                       [selected? false]
                                                       [color GREEN]
                                                       [buddies empty]
                                                       [toys empty]
                                                       [mx 0][my 0]))]))


(begin-for-test
  (check-equal? (send world1 on-draw) world-on-draw
                "Test case to check on-draw of world")
  (check-equal? (send world1 target-x) 200
                "Test case to check target-x for world")
  (check-equal? (send world1 target-y) 250
                "Test case to check target-y for world")
  (check-false  (send world1 target-selected?)  
                "Test case to check target-x for world")
  (check-equal? (send world1 target-color) BLACK
                "Test case to check target-x for world")
  (send world1 on-tick)
  (check-true (compare-world? world1 world1)
              "Test case to check the on tick method for world")
  (send world1 on-mouse 20 20 "button-down")
  (check-true (compare-world? world1 world-button-down)
              "Test case to check the button-down mouse event for world")
  
  ;; Sequential test cases to check overlapping square
  ;; Creates one square on empty-world
  (send empty-world-for-square1 on-key "s")
  (check-false (compare-world?  empty-world-for-square1 world-with-square1)
              "Test case to check the key event s")
  (send empty-world-for-square1 on-mouse 200 250 "button-down")
  (send empty-world-for-square1 on-mouse 300 150 "drag")
  (send empty-world-for-square1 on-mouse 300 150 "button-up")
  
  ;; Creates second square on empty-world and drags it to overlap
  ;; with the existig square in empty-world
  (send empty-world-for-square1 on-key "s")
  (check-false (compare-world?  empty-world-for-square1 world-with-square1)
              "Test case to check the key event s")
  (send empty-world-for-square1 on-mouse 200 250 "button-down")
  (send empty-world-for-square1 on-mouse 300 150 "drag")
  (send empty-world-for-square1 on-mouse 300 150 "button-up")
  (send empty-world-for-square1 on-mouse 300 150 "button-down")
  (send empty-world-for-square1 on-mouse 350 190 "drag")
  (send empty-world-for-square1 on-mouse 350 190 "button-up")
  
  ;; Creates a square to drag it to any other location to avoid overlapping
  (send empty-world-for-square1 on-key "s")
  (check-false (compare-world?  empty-world-for-square1 world-with-square1)
              "Test case to check the key event s")
  (send empty-world-for-square1 on-mouse 200 250 "button-down")
  (send empty-world-for-square1 on-mouse 200 150 "drag")
  (send empty-world-for-square1 on-mouse 200 150 "button-up")
  
  (send empty-world-for-square1 on-key "c")
  (check-true (compare-world?  empty-world-for-square1 empty-world-for-square1)
              "Test case to check the key event for key other than s" ))


;; Test Cases for Target%

(define target1 (new Target% [x 200][y 250] [selected? false]
                                            [color BLACK]
                                            [mx 0][my 0]))

(define target-button-down (new Target% [x 200][y 250] 
                                        [selected? true]
                                        [color ORANGE]
                                        [mx 205][my 255]))

(define target-button-up (new Target% [x 200][y 250] 
                                      [selected? false]
                                      [color BLACK]
                                      [mx 0][my 0]))

(define target-drag (new Target% [x 15][y 15] 
                                 [selected? true]
                                 [color ORANGE]
                                 [mx 20][my 20]))

(begin-for-test
  (send target1 on-mouse 205 255 "button-down")
  (check-true (send target1 for-test:testing-case target-button-down)
              "Test case to check the button down event for target")
  (send target1 on-mouse 205 255 "button-up")
  (check-true (send target1 for-test:testing-case target-button-up)
              "Test case to check the button up event for target")
  (send target-button-down on-mouse 20 20 "drag")
  (check-true (send target-button-down for-test:testing-case target-drag)
              "Test case to check the drag event for selected target")
  (send target-button-up on-mouse 20 20 "drag")
  (check-true (send target-button-up for-test:testing-case target-button-up)
              "Test case to check drag event for unselected target")
  (send target1 on-mouse 20 20 "move")
  (check-true (send target1 for-test:testing-case target1)
              "Test case to check mouse event other than the required three"))

;; Test cases for Squaretoy

(define square1 (new SquareToy% [x 100] [y 100]
                                [selected? false]
                                [color GREEN]
                                [buddies 
                                 (list(new SquareToy% [x 50] [y 50]
                                [selected? false]
                                [color GREEN]
                                [buddies empty] 
                                [toys empty]
                                [mx 0][my 0]))] 
                                [toys empty]
                                [mx 0][my 0]))

(define square-button-down (new SquareToy% [x 100] [y 100]
                                [selected? true]
                                [color RED]
                                [buddies 
                                 (list(new SquareToy% [x 50] [y 50]
                                [selected? true]
                                [color RED]
                                [buddies empty] 
                                [toys empty]
                                [mx 0][my 0]))] 
                                [toys empty]
                                [mx 110][my 110]))

(define square2 (new SquareToy% [x 150] [y 150]
                                [selected? true]
                                [color RED]
                                [buddies empty] 
                                [toys empty]
                                [mx 0][my 0]))

(define square-button-up (new SquareToy% [x 150] [y 150]
                                [selected? false]
                                [color GREEN]
                                [buddies empty] 
                                [toys empty]
                                [mx 0][my 0]))

(define square3 (new SquareToy% [x 100] [y 100]
                                [selected? true]
                                [color RED]
                                [buddies empty] 
                                [toys empty]
                                [mx 0][my 0]))


(begin-for-test
  (check-equal? (send square1 toy-color) GREEN)
  (send square1 on-mouse 100 100 "drag")
  (check-true (send square1 for-test:testing-case square1)
              "Test case to check drag event for unselected square")
  (send square1 on-mouse 110 110 "button-down")
  (check-true (send square1 for-test:testing-case square-button-down)
              "Test case to check button-down event for square")
  (send square2 on-mouse 110 110 "button-up")
  (check-true (send square2 for-test:testing-case square-button-up)
              "Test case to check button-up event for square")
  (send square2 on-mouse 110 110 "move")
  (check-true (send square2 for-test:testing-case square2)
              "Test case to check mouse events other than required three
               for square"))


                        


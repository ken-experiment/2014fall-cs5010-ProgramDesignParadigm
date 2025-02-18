;; toys.rkt
;; Set10-Question 1
;; Zoltan Wang, Pankaj Tripathi

;; Use (run rate speed) to run the program
;; Where rate is a positive number and speed is a positive integer
;; Toys in world of canvas that is 400x500 pixels with circle of radius 10 in
;; outline mode as target 
;; toys in world are
;; 1) child types "s", a new square-shaped(40*40) toy pops up on canvas and 
;; travelling rightward at a constant rate, bounces back from wall of canvas
;; 2)child types "c", a new circle-shaped toy of radius 5 appears and changes
;; colors from green and red on every 5 ticks
;; 3)target will have property of smooth drag
;; All of these functionalities are implemented with stateful objects

#lang racket
(require rackunit)
(require "extras.rkt")
(require 2htdp/universe)   
(require 2htdp/image)

(provide World%)
(provide SquareToy%)
(provide CircleToy%)
(provide make-world)
(provide run)
(provide make-square-toy)
(provide make-circle-toy)
(provide StatefulWorld<%>)
(provide StatefulToy<%>)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;                                CONSTANTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define ZERO 0)
(define MINUS-ONE -1)
(define FOUR 4)
(define FIVE 5)
(define TEN 10)

(define SOLID "solid")
(define OUTLINE "outline")
(define GREEN "green")
(define RED "red")

(define SQUARE-LENGTH 40)
(define HALF-SQUARE-LENGTH (/ SQUARE-LENGTH 2))
(define SQUARE-IMAGE (square 40 "outline" "green"))

(define CIRCLE-RADIUS 5)

(define TARGET-RADIUS 10)
(define TARGET-IMAGE (circle 10 "outline" "red"))

(define CANVAS-WIDTH 400)
(define CANVAS-HEIGHT 500)
(define HALF-CANVAS-WIDTH (/ CANVAS-WIDTH 2))
(define HALF-CANVAS-HEIGHT (/ CANVAS-HEIGHT 2))
(define EMPTY-CANVAS (empty-scene CANVAS-WIDTH CANVAS-HEIGHT))

(define LEFT-EDGE HALF-SQUARE-LENGTH)
(define RIGHT-EDGE (- CANVAS-WIDTH HALF-SQUARE-LENGTH))

(define BUTTON-DOWN "button-down")
(define BUTTON-UP "button-up")
(define DRAG "drag")
(define RIGHT "right")
(define LEFT "left")
(define S "s")
(define C "c")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;                           DATA DEFINITION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Direction is one of
;; -- "RIGHT"   -- square is moving to the right
;; -- "LEFT"    -- square is moving to the left
;;TEMPLATE
;; direction-fn:  Direction -> ??
;; (define (direction-fn direction)
;;   (cond
;;     [(string=? direction RIGHT) ...]
;;     [(string=? direction LEFT) ...]))


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

;; ColorString is a string that depicts the color of StatefulToy<%> 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;                              INTERFACES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define StatefulWorld<%>
  (interface ()

    ;; -> Void
    ;; EFFECT: updates this StatefulWorld<%> to the state that it should 
    ;; be in after
    ;; a tick.
    on-tick                             

    ;; Integer Integer MouseEvent -> Void
    ;; EFFECT: updates this StatefulWorld<%> to the state that it should be in
    ;; after the given MouseEvent
    on-mouse

    ;; KeyEvent -> Void
    ;; EFFECT: updates this StatefulWorld<%> to the state that it should be in
    ;; after the given KeyEvent
    on-key

    ;; -> Scene
    ;; Returns a Scene depicting this StatefulWorld<%>
    ;; on it.
    on-draw 
    
    ;; -> Integer
    ;; RETURN: the x and y coordinates of the target
    target-x
    target-y

    ;; -> Boolean
    ;; Is the target selected?
    target-selected?

    ;; -> ListOfStatefulToy<%>
    get-toys

))

;-------------------------------------------------------------------------------

(define StatefulToy<%>
    (interface ()

    ;; -> Void
    ;; EFFECT: updates this StatefulToy<%> to the state it should be in after a
    ;; tick. 
    on-tick                             

    ;; Scene -> Scene
    ;; Returns a Scene like the given one, but with this StatefulToy<%> drawn
    ;; on it.
    add-to-scene

    ;; -> Int
    toy-x
    toy-y

    ;; -> ColorString
    ;; returns the current color of this toy StatefulToy<%>
    toy-color

    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                               CLASS WORLD
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; World%     -- a class that satisfies the StatefulWorld<%> interface
;; A World is a (new World% [target Target] [toys ListOfStatefulToy<%>]  
;;[speed PosInt])
;; INTERP: It represents a world, which has a Target, a list of toys and speed 
;;         with which toys move

(define World%
  (class* object% (StatefulWorld<%>)         
    (init-field 
     target    ;; it is a circle of radius 10
     toys      ;; toys can include number of squares and circles
               ;; a toy can be square moving right or it can be 
               ;; color changing circle
     speed)    ;; it is speed with which square moves from left to right
    
    (super-new)
    
    ;; on-tick: -> Void
    ;; EFFECT: updates this StatefulWorld<%> to the state that it should 
    ;; be in after a tick.
    ;; EXAMPLES: if world1 is StatefulWorld<%> then (send world1 on-tick) will 
    ;;           return a world that should follow after a tick
    ;; STRATEGY: High Order Function Composition
    (define/public (on-tick)
      (for-each
       ;; StatefulToy<%> -> Void
       ;; GIVEN: a toy which can be circle or square
       ;; EFFECT: a toy like given that should follow 
       ;; after a tick
       (lambda (toy) (send toy on-tick))
       toys))
    
    ;; on-mouse: Integer Integer MouseEvent -> Void
    ;; GIVEN: x and y coordinates of mouse pointer and mousevent
    ;; EFFECT: updates this StatefulWorld<%> to the state that it should be in
    ;; after the given MouseEvent
    ;; EXAMPLES: if world1 is StatefulWorld<%> then 
    ;;           (send world1 on-mouse 20 20 "button-down") will return stateful
    ;;           world object world-button-down
    ;; STRATEGY: Function Composition
    (define/public (on-mouse x y evt)
      (send target on-mouse x y evt))
      
    ;; on-key: KeyEvent -> Void
    ;; GIVEN: A KeyEvent
    ;; EFFECT: updates this StatefulWorld<%> to the state that it should be in
    ;; after the given KeyEvent
    ;; EXAMPLES: if world1 is StatefulWorld<%> then 
    ;;           (send empty-world-for-square on-key "s") will return stateful
    ;;           world object world-with-square
    ;; STRATEGY: Cases on kev: KeyEvent
    (define/public (on-key kev)
      (cond
        [(key=? kev S)
         (set! toys (cons (make-square-toy (target-x) (target-y) speed) toys))]
        [(key=? kev C)
         (set! toys (cons (make-circle-toy (target-x) (target-y)) toys))]
        [else this]))
    
    ;; on-draw: -> Scene
    ;; RETURNS: a Scene depicting this StatefulWorld<%>
    ;; on it.
    ;; EXAMPLES: (send world1 on-draw) = world-on-draw
    ;; STRATEGY: High Order Function Composition
    (define/public (on-draw)
      (local
        ((define scene-with-target (send target on-draw EMPTY-CANVAS)))
        (foldr
         ;; StatefulToy<%> Scene -> Scene
         ;; GIVEN: a toy and a scene
         ;; RETURNS: a scene after toy is painted on it
         (lambda (toy scene)
           (send toy add-to-scene scene))
         scene-with-target
         toys)))
    
    ;; target-x: -> Integer
    ;; target-y: -> Integer
    ;; RETURNS: below mentioned functions returns x and y coordinates of
    ;;          the target
    ;; EXAMPLES: These methods return the x and y coordinates of center of the 
    ;;           target when called on Target% object
    ;; STRATEGY: Function Composition
    (define/public (target-x) (send target target-x))
    (define/public (target-y) (send target target-y))
    
    ;; target-selected?: -> Boolean
    ;; RETURNS: true if the target is selected
    ;; EXAMPLES: These methods return whether the target is selected or not.
    ;;           if it is selected then it returns true else it returns false.
    ;; STRATEGY: Function Composition
    (define/public (target-selected?) (send target target-selected?))
    
    ;; get-toys: -> ListOfStatefulToy<%>
    ;; RETURNS: all toys in the world
    ;; EXAMPLES: This method returns the list of toys when called on the 
    ;;           object of class World%.
    ;; STRATEGY: Function Composition
    (define/public (get-toys) toys)
    
    ;; Methods to be used for testing
    
    ;; world-target: -> Target%
    ;; RETURNS: a Target% object
    ;; EXAMPLES: This method returns the target when called on object of class
    ;;           World%.
    ;; STRATEGY: Function Composition
    (define/public (world-target) target)
    
    ;; world-speed: -> PosInt
    ;; RETURNS: a speed with which the square toy moves
    ;; EXAMPLES: This method returns the speed with which the square toy moves
    ;;           when called on object of class World%.
    ;; STRATEGY: Function Composition
    (define/public (world-speed) speed)
     
    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;                              CLASS TARGET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; A Target is a (new Target% [x Integer] [y Integer] [selected? Boolean]
;;                            [mx Integer] [my Integer])
;; INTERP: It represents a Target, which it self is a circle and can be smoothly
;; dragged on the canvas

(define Target%
  (class* object% (StatefulWorld<%>)         
    (init-field 
     x                      ;; the x position of the target
     y                      ;; the y position of the target
     [selected? false]      ;; indicate whether the target is selected
     [mx ZERO]              ;; the x position of the mouse pointer in the target
     [my ZERO])             ;; the y position of the mouse pointer in the target
    
    (super-new)
    
    ;; on-tick: -> Void
    ;; EFFECT: updates this Target% to the state that it should 
    ;; be in after a tick.
    ;; EXAMPLES: It gives the target that should follow after tick 
    ;;           when called on Target% object. It gives the current location
    ;;           and state(selected or not) of the target after a tick. 
    ;; STRATEGY: Function Composition
    (define/public (on-tick)
      this)
    
    ;; on-mouse: Integer Integer MouseEvent -> Void
    ;; GIVEN: x and y coordinates of mouse pointer and mousevent
    ;; EFFECT: updates this Target% to the state that it should be in
    ;; after the given MouseEvent
    ;; EXAMPLES: This method gives the target that should follow after it's 
    ;            called with mouse position and the mouse event. Based on the
    ;;           mouse event which are namely button-down, button-up, drag the
    ;;           corresponding methods are called
    ;; STRATEGY: Cases on evt: MouseEvent
    (define/public (on-mouse mouse-x mouse-y evt)
      (cond
        [(mouse=? evt BUTTON-DOWN) (target-after-button-down mouse-x mouse-y)]
        [(mouse=? evt DRAG) (target-after-drag mouse-x mouse-y)]
        [(mouse=? evt BUTTON-UP) (target-after-button-up)]
        [else this]))
    
    ;; target-after-button-down : Integer Integer -> Void
    ;; GIVEN: the location of a mouse event
    ;; EFFECT: the target that should follow this one after a button
    ;; down at the given location
    ;; DETAILS:  If the event is inside
    ;; the target, returns a target just like this target, except that it is
    ;; selected.  Otherwise returns the target unchanged.
    ;; EXAMPLES: This method returns the target with it being selected only 
    ;;           if the mouse pointers are in the target when called on 
    ;;           Target% object else it will return the calling object as it is 
    ;; STRATEGY: Function Composition
    (define/public (target-after-button-down mouse-x mouse-y)
      (if (in-target? mouse-x mouse-y)
          (set-button-down mouse-x mouse-y)
          this))
     
    ;; set-button-down : Integer Integer -> Void
    ;; GIVEN: the location of a mouse event
    ;; EFFECT: the target that should follow this one after a button
    ;; down at the given location
    ;; EXAMPLES: This method returns the target with it being selected only 
    ;;           if the mouse pointers are in the target when called on 
    ;;           Target% object
    ;; STRATEGY: Function Composition
    (define/public (set-button-down mouse-x mouse-y)
      (set! selected? true)
      (set! mx mouse-x)
      (set! my mouse-y))
    
    ;; target-after-drag : Integer Integer -> Void
    ;; GIVEN: the location of a mouse event
    ;; EFFECT: the target that should follow this one after a drag at
    ;; the given location 
    ;; DETAILS: if target is selected, move the target to the mouse location,
    ;; otherwise ignore.
    ;; EXAMPLES: This method retuerns the changed location of the target 
    ;;           with it being selected and dragged to a new location. If the
    ;;           target is not selected it will return the calling object
    ;; STRATEGY: Function Composition
    (define/public (target-after-drag mouse-x mouse-y)
      (if selected?
          (set-drag mouse-x mouse-y)
          this))
    
    ;; set-drag : Integer Integer -> Void
    ;; GIVEN: the location of a mouse event
    ;; EFFECT: the target that should follow this one after a drag at
    ;; the given location 
    ;; EXAMPLES: This method retuerns the changed location of the target 
    ;;           with it being selected and dragged to a new location
    ;; STRATEGY: Function Composition
    (define/public (set-drag mouse-x mouse-y)
      (set! x (+ x (- mouse-x mx)))
      (set! y (+ y (- mouse-y my)))
      (set! mx mouse-x)
      (set! my mouse-y))
    
    ;; target-after-button-up : -> Void
    ;; EFFECT: the target that should follow this one after a button-up
    ;; DETAILS: button-up unselects all targets
    ;; EXAMPLES: This method returns the location of the target with it being 
    ;;           unselected when called on Target% object
    ;; STRATEGY: Function Composition
    (define/public (target-after-button-up)
      (set! selected? false))
    
    ;; in-target? : Integer Integer -> Boolean
    ;; GIVEN: a location of mouse pointer on the canvas
    ;; RETURNS: true iff the location is inside this target.
    ;; EXAMPLES: This method checks and returns a boolean value if the mouse
    ;;           pointer is in the target. It returns true if mouse pointer
    ;;           is in the target else false
    ;; STRATEGY: Function Composition
    (define/public (in-target? other-x other-y)
      (<= (+ (sqr (- x other-x)) (sqr (- y other-y)))
          (sqr TARGET-RADIUS)))
    
    ;; on-key: KeyEvent -> Void
    ;; GIVEN: KeyEvent
    ;; EFFECT: updates this Target% to the state that it should be in
    ;; after the given KeyEvent
    ;; EXAMPLES: This method returns the target object as it is after it is
    ;;           called on Target% object 
    ;; STRATEGY: Function Composition
    (define/public (on-key kev)
      this)
    
    ;; on-draw: -> Scene
    ;; RETURNS: a Scene depicting this world
    ;; with target added on it.
    ;; EXAMPLES: This method will add a target that is a circle of radius
    ;;           10 pixels to the scene when called on Target% object.
    ;; STRATEGY: Function Composition
    (define/public (on-draw scene)
      (place-image TARGET-IMAGE x y scene))
    
    ;; target-x: -> Integer
    ;; target-y: -> Integer
    ;; RETURNS: the x and y coordinates of the target
    ;; EXAMPLES: These methods return the x and y coordinates of center of 
    ;;           the target when called on Target% object          
    ;; STRATEGY: Function Composition
    (define/public (target-x) x)
    (define/public (target-y) y)
    
    ;; target-selected?: -> Boolean
    ;; RETURNS: Is the target selected?
    ;; EXAMPLES: These methods return whether the target is selected or not.
    ;;           if it is selected then it returns true else it returns false.
    ;; STRATEGY: Function Composition
    (define/public (target-selected?) selected?)
    
    ;; get-toys: -> ListOfStatefulToy<%>
    ;; RETURNS: empty. no toys present in target
    ;; EXAMPLES: This method returns empty list as target won't have any toys 
    ;;           in it when called on Target% object
    ;; STRATEGY: Function Compositon
    (define/public (get-toys) empty)
    
    ;; Methods to be used for testing
    
    ;; target-mx: -> Integer
    ;; target-my: -> Integer
    ;; RETURNS: the x and y coordinates of center of the mouse pointer
    ;; EXAMPLES: This method returns the mouse pointers position when called on
    ;;           Target% object.
    ;; STRATEGY: Function Composition
    (define/public (target-mx) mx)
    (define/public (target-my) my)
    
    ;; for-test:testing-case: StatefulToy<%> -> Boolean
    ;; GIVEN: a Target%.
    ;; RETURNS: true if the current calling target object has same values as 
    ;;          obtained when individual functions are called for each field
    ;; EXAMPLES: This method returns true if the current calling target object
    ;;           has same values as obtained when individual functions are 
    ;;           called for each field else it will return false.
    ;; STRATEGY: Function Composition
    (define/public (for-test:testing-case obj)
      (and (= x (send obj target-x))
           (= y (send obj target-y))
           (equal? selected? (send obj target-selected?))
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
     x                     ;; the x position of the toy
     y                     ;; the y position of the toy
     speed                 ;; the speed with which the toy travels
     [direction RIGHT]     ;; indicates the direction of the  moving square
     [color GREEN])        ;; indicate the color of the toy
    
    (super-new)
    
    ;; on-tick: -> Void
    ;; EFFECT: updates this StatefulToy<%> to the state it should be in after a
    ;; tick.
    ;; EXAMPLES: It gives the square toy that should follow after tick 
    ;;           when called on SquareToy% object. It gives the direction
    ;;           and speed of the square toy after a tick. 
    ;; STRATEGY: Structural Decompostion on direction: Direction
    (define/public (on-tick)
      (cond
        [(string=? direction RIGHT) (move-right)]
        [(string=? direction LEFT) (move-left)]))
    
    ;; move-right: -> Void
    ;; EFFECT: updates this StatefulToy<%> to the state it should be in after a
    ;; tick.
    ;; EXAMPLES: This method checks whether the square toy is moving in the 
    ;;           right direction  and if while moving to right it touches the
    ;;           wall then it should change its direction and start moving left
    ;; STRATEGY: Function Composition
    (define/public (move-right)
      (if (>= (+ x speed) RIGHT-EDGE)
          (move-right-change)
          (set! x (+ x speed))))
    
    ;; move-right-change: -> Void
    ;; EFFECT: updates this StatefulToy<%> to the state it should be in after a
    ;; tick.
    ;; EXAMPLES: This method changes the directon of the square toy to left and 
    ;;           updates it x coordinate by setting it to RIGHT-EDGE
    ;; STRATEGY: Function Composition
    (define/public (move-right-change)
      (set! x RIGHT-EDGE)
      (set! direction LEFT))
    
    ;; move-left: -> Void
    ;; EFFECT: updates this StatefulToy<%> to the state it should be in after a
    ;; tick.
    ;; EXAMPLES: This method checks whether the square toy is moving in the 
    ;;           left direction  and if while moving to left it touches the
    ;;           wall then it should change its direction and start moving right
    ;; STRATEGY: Function Composition
    (define/public (move-left)
      (if (<= (- x speed) LEFT-EDGE)
          (move-left-change)
          (set! x (- x speed))))
    
    ;; move-left-change: -> Void
    ;; EFFECT: updates this StatefulToy<%> to the state it should be in after a
    ;; tick.
    ;; EXAMPLES: This method changes the directon of the square toy to right 
    ;;           and updates it x coordinate by setting it to LEFT-EDGE
    ;; STRATEGY: Function Composition
    (define/public (move-left-change)
      (set! x LEFT-EDGE)
      (set! direction RIGHT))
    
    ;; add-to-scene: Scene -> Scene
    ;; RETURNS: a Scene like the given one, but with this StatefulToy<%> drawn
    ;; on it.
    ;; EXAMPLES: This method will add a square toy that is a square of side 40
    ;;           pixels to the scene when called on SquareToy% object.
    ;; STRATEGY: Function Composition
    (define/public (add-to-scene scene)
      (place-image SQUARE-IMAGE x y scene))
    
    ;; toy-x: -> Integer
    ;; toy-y: -> Integer
    ;; RETURNS: x and y coordinates of the square toy repectively
    ;; EXAMPLES: These methods return the x and y coordinates of center of 
    ;;           the square toy when called on SquareToy% object          
    ;; STRATEGY: Function Composition
    (define/public (toy-x) x)
    (define/public (toy-y) y)
    
    ;; toy-color: -> ColorString
    ;; RETURNS: the current color of this toy
    ;; EXAMPLES: This method returns the color of the square which will be green
    ;;           when called on SquareToy% object.
    ;; STRATEGY: Function Composition
    (define/public (toy-color) color)
    
    ;; Methods to be used for testing
    
    ;; toy-speed: -> PosInt
    ;; RETURNS: speed of SquareToy%
    ;; EXAMPLES: This method returns the speed with which the square toy is
    ;;           moving when called on SquareToy% object.
    ;; STRATEGY: Function Composition
    (define/public (toy-speed) speed)
    
    ;; toy-direction: -> Direction
    ;; RETURNS: direction of SquareToy%
    ;; EXAMPLES: This method returns the direction in which the square toy is
    ;;           moving when called on SquareToy% object.
    ;; STRATEGY: Function Composition
    (define/public (toy-direction) direction)
    
    ;; for-test:testing-case: SquareToy% -> Boolean
    ;; GIVEN: a SquareToy%.
    ;; RETURNS: true if the current calling SquareToy% object has same values  
    ;;          as obtained when individual functions are called for each field
    ;; EXAMPLES: This method returns true if the current calling SquareToy% 
    ;;           object has same values as obtained when individual functions  
    ;;           are called for each field else it will return false.
    ;; STRATEGY: Function Composition
    (define/public (for-test:testing-case obj)
      (and (= x (send obj toy-x))
           (= y (send obj toy-y))
           (= speed (send obj toy-speed))
           (string=? direction (send obj toy-direction))
           (equal? color (send obj toy-color))))
    
    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;                            CLASS CIRCLETOY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; CircleToy% -- a class that satisfies the StatefulToy<%> interface
;; A CircleToy is a (new CircleToy% [x Integer] [y Integer] 
;;                                  [count NonNegInt][color ColorString]
;; INTERP: A CircleToy represents a circle-shaped toy

(define CircleToy%
  (class* object% (StatefulToy<%>)
    (init-field 
     x                     ;; the x position of the toy
     y                     ;; the y position of the toy
     [count ZERO]          ;; a counter to count the number of ticks of the toy
     [color GREEN])        ;; indicates the color of the toy that changes with
                           ;; every five ticks
    
    (super-new)
    
    ;; on-tick: -> Void
    ;; EFFECT: updates this StatefulToy<%> to the state it should be in after a
    ;; tick.
    ;; EXAMPLES: It gives the circle toy that should follow after tick 
    ;;           when called on CircleToy% object. It gives the count
    ;;           and olor of the CircleToy% after a tick. 
    ;; STRATEGY: Function Composition
    (define/public (on-tick)
      (if (= count FOUR)
          (change-state)
          (set! count (add1 count))))
          
    ;; change-state: -> Void
    ;; EFFECT: updates this StatefulToy<%> to the state it should be in after a
    ;; tick.
    ;; EXAMPLES: This method returns the CircleToy% with its status that is its 
    ;;           counter for the tick set to zero and its color changed on 
    ;;           fifth tick
    ;; STRATEGY: Function Composition
    (define/public (change-state)
      (local
        ((define color-changed 
           (if (string=? color GREEN) RED GREEN)))
        (set! count ZERO)
        (set! color color-changed)))
    
    ;; add-to-scene: Scene -> Scene
    ;; RETURNS: a Scene like the given one, but with this StatefulToy<%> drawn
    ;; on it.
    ;; EXAMPLES: This method will add a cirlce toy that is a circle of radius 5
    ;;           pixels to the scene when called on CircleToy% object.
    ;; STRATEGY: Function Composition
    (define/public (add-to-scene scene)
      (place-image (circle CIRCLE-RADIUS SOLID color) x y scene))
    
    ;; toy-x:-> Int
    ;; toy-y:-> Int
    ;; RETURNS: x and y coordinates of this toy
    ;; EXAMPLES: These methods return the x and y coordinates of center of 
    ;;           the circle toy when called on CircleToy% object          
    ;; STRATEGY: Function Composition
    (define/public (toy-x) x)
    (define/public (toy-y) y)
    
    ;; toy-color:-> ColorString
    ;; RETURNS: the current color of this toy
    ;; EXAMPLES: This method returns the color of the circle toy which changes
    ;;           after every fifth tick. It will be green initially.
    ;; STRATEGY: Function Composition
    (define/public (toy-color) color)
    
    ;; Methods to be used for testing
    
    ;; toy-count: -> NonNegInt
    ;; RETURNS: the current color of this toy
    ;; EXAMPLES: This method returns the color of the circle toy which changes
    ;;           after every fifth tick. It will be green initially.
    ;; STRATEGY: Function Composition
    (define/public (toy-count) count)
    
    ;; for-test:testing-case: CircleToy% -> Boolean
    ;; GIVEN: a CircleToy%.
    ;; RETURNS: true if the current calling CircleToy% object has same values  
    ;;          as obtained when individual functions are called for each field
    ;; EXAMPLES: This method returns true if the current calling CircleToy% 
    ;;           object has same values as obtained when individual functions  
    ;;           are called for each field else it will return false.
    ;; STRATEGY: Function Composition
    
    (define/public (for-test:testing-case obj)
      (and (= x (send obj toy-x))
           (= y (send obj toy-y))
           (= count (send obj toy-count))
           (equal? color (send obj toy-color))))
    
    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;                            MAKE-WORLD FUNCTION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; make-world : PosInt -> World%
;; GIVEN: a positive integer which is speed in (in pixels/tick).
;; RETURNS: a world with a target, but no toys, and in which any
;; toys created in the future will travel at the given speed (in pixels/tick).
;; EXAMPLES: This method returns a World% object when called with speed passed
;;           to it. A world with a target, but no toys, and in which any
;;           toys created in the future will travel at the given speed 
;;           (in pixels/tick).
;; STRATEGY: Function Composition

(define (make-world s)
  (new World% 
       [target (new Target% [x HALF-CANVAS-WIDTH][y HALF-CANVAS-HEIGHT])]
       [toys empty]
       [speed s]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;                              RUN FUNCTION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; run : PosNum PosInt -> World%
;; GIVEN: a frame rate (in seconds/tick) and a square-speed (in pixels/tick),
;;       creates and runs a world.  
;; EFFECT: the final state of the world.
;; STRATEGY: High Order Function Composition

(define (run rate speed)
  (big-bang (make-world speed)
            (on-tick
             ;; StatefulWorld<%> -> StatefulWorld<%>
             ;; GIVEN: a world
             ;; RETURNS: a world that should follow after tick
             (lambda (w) (send w on-tick) w) rate)
            (on-draw
             ;; StatefulWorld<%> -> Scene
             ;; GIVEN: a world
             ;; RETURNS: a world drawn on the scene
             (lambda (w) (send w on-draw)))
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
;;;;                        MAKE-SQUARE-TOY FUNCTION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; make-square-toy : PosInt PosInt PosInt -> SquareToy%
;; GIVEN: an x and a y position, and a speed
;; RETURNS: an object representing a square toy at the given position,
;;          travelling right at the given speed.
;; EXAMPLES: This method returns a an object representing a square toy at the 
;;           given position, travelling right at the given speed. It is called
;;           with the position and speed of square toy passed to it.
;; STRATEGY: Function Composition

(define (make-square-toy tgt-x tgt-y tgt-speed)
  (new SquareToy% 
       [x tgt-x]
       [y tgt-y]
       [speed tgt-speed]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;                        MAKE-CIRCLE-TOY FUNCTION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; make-circle-toy : PosInt PosInt -> CircleToy%
;; GIVEN: an x and a y position
;; RETURNS: an object representing a circle toy at the given position.
;; EXAMPLES: This method returns a an object representing circle toy at the 
;;           given position. It is called with the position of circle toy passed
;;           to it.          
;; STRATEGY: Function Composition

(define (make-circle-toy tgt-x tgt-y)
  (new CircleToy% 
       [x tgt-x]
       [y tgt-y]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;                                  TESTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define world-on-draw
  (place-image (square 40 "outline" "green") 300 150
               (place-image (circle 5 "solid" "green") 200 200
                            (place-image (circle 10 "outline" RED) 
                                         200 250 EMPTY-CANVAS))))

(define empty-world (make-world 8))
(define empty-world-for-square (make-world 8))
(define empty-world-for-circle (make-world 8))

(define target1 (new Target% [x HALF-CANVAS-WIDTH] [y HALF-CANVAS-HEIGHT]
                            [selected? false] [mx 0] [my 0]))

(define square1 (new SquareToy% [x 370] [y HALF-CANVAS-HEIGHT] 
                                   [speed 8][direction RIGHT] [color GREEN]))

(define square2 (new SquareToy% [x 360] [y HALF-CANVAS-HEIGHT] 
                                   [speed 8][direction RIGHT] [color GREEN]))

(define world1 (new World% [target (new Target% [x 200][y 250]
                                                [selected? false]
                                                [mx 0][my 0])]
                           [toys (list (new SquareToy% [x 300][y 150]
                                                      [speed 8][direction RIGHT]
                                                      [color GREEN])
                                       (new CircleToy% [x 200][y 200]
                                                       [count 0][color GREEN]))]
                           [speed 8]))

(define world-button-down (new World% [target (new Target% [x 200][y 250]
                                                [selected? false]
                                                [mx 0][my 0])]
                           [toys (list (new SquareToy% [x 300][y 150]
                                                      [speed 8][direction RIGHT]
                                                      [color GREEN])
                                       (new CircleToy% [x 200][y 200]
                                                       [count 0][color GREEN]))]
                           [speed 8]))

(define world2 (new World% [target (new Target% [x 200][y 250]
                                                [selected? false]
                                                [mx 0][my 0])]
                           [toys (list (new SquareToy% [x 308][y 150]
                                                      [speed 8][direction RIGHT]
                                                      [color GREEN])
                                       (new CircleToy% [x 200][y 200]
                                                       [count 1][color GREEN]))]
                           [speed 8]))

(define world3 (new World% [target (new Target% [x 200][y 250]
                                                [selected? false]
                                                [mx 0][my 0])]
                           [toys (list (new SquareToy% [x 300][y 150]
                                                      [speed 8][direction RIGHT]
                                                      [color GREEN]))]
                           [speed 8]))

(define world4 (new World% [target (new Target% [x 200][y 250]
                                                [selected? false]
                                                [mx 0][my 0])]
                           [toys (list (new SquareToy% [x 308][y 150]
                                                      [speed 8][direction RIGHT]
                                                      [color GREEN]))]
                           [speed 8]))

(define world5 (new World% [target (new Target% [x 200][y 250]
                                                [selected? false]
                                                [mx 0][my 0])]
                           [toys (list (new CircleToy% [x 300][y 150]
                                                       [count 4][color RED]))]
                           [speed 8]))

(define world6 (new World% [target (new Target% [x 200][y 250]
                                                [selected? false]
                                                [mx 0][my 0])]
                           [toys (list (new CircleToy% [x 300][y 150]
                                                      [count 0][color GREEN]))]
                           [speed 8]))

(define world7 (new World% [target (new Target% [x 200][y 250]
                                                [selected? false]
                                                [mx 0][my 0])]
                           [toys (list (new CircleToy% [x 300][y 150]
                                                      [count 3][color GREEN]))]
                           [speed 8]))

(define world8 (new World% [target (new Target% [x 200][y 250]
                                                [selected? false]
                                                [mx 0][my 0])]
                           [toys (list (new CircleToy% [x 300][y 150]
                                                      [count 4][color GREEN]))]
                           [speed 8]))

(define world9 (new World% [target (new Target% [x 200][y 250]
                                                [selected? false]
                                                [mx 0][my 0])]
                           [toys (list (new SquareToy% [x 400][y 150]
                                                      [speed 8][direction RIGHT]
                                                      [color GREEN]))]
                           [speed 8]))

(define world10 (new World% [target (new Target% [x 200][y 250]
                                                [selected? false]
                                                [mx 0][my 0])]
                           [toys (list (new SquareToy% [x 380][y 150]
                                                      [speed 8][direction LEFT]
                                                      [color GREEN]))]
                           [speed 8]))

(define world11 (new World% [target (new Target% [x 200][y 250]
                                                [selected? false]
                                                [mx 0][my 0])]
                           [toys (list (new SquareToy% [x 0][y 150]
                                                       [speed 8][direction LEFT]
                                                       [color GREEN]))]
                           [speed 8]))

(define world12 (new World% [target (new Target% [x 200][y 250]
                                                [selected? false]
                                                [mx 0][my 0])]
                           [toys (list (new SquareToy% [x 20][y 150]
                                                      [speed 8][direction RIGHT]
                                                      [color GREEN]))]
                           [speed 8]))

(define world13 (new World% [target (new Target% [x 200][y 250]
                                                [selected? false]
                                                [mx 0][my 0])]
                           [toys (list (new SquareToy% [x 20][y 150]
                                                      [speed 8][direction RIGHT]
                                                      [color GREEN]))]
                           [speed 8]))

(define world14 (new World% [target (new Target% [x 200][y 250]
                                                [selected? true]
                                                [mx 205][my 255])]
                           [toys (list (new SquareToy% [x 20][y 150]
                                                     [speed 8][direction RIGHT]
                                                     [color GREEN]))]
                           [speed 8]))

(define world15 (new World% [target (new Target% [x 200][y 250]
                                                [selected? false]
                                                [mx 0][my 0])]
                           [toys (list (new CircleToy% [x 300][y 150]
                                                       [count 4][color GREEN]))]
                           [speed 8]))

(define world16 (new World% [target (new Target% [x 200][y 250]
                                                [selected? false]
                                                [mx 0][my 0])]
                           [toys (list (new CircleToy% [x 300][y 150]
                                                      [count 0][color RED]))]
                           [speed 8]))
(define world17 (new World% [target (new Target% [x 200][y 250]
                                                [selected? false]
                                                [mx 0][my 0])]
                           [toys (list (new SquareToy% [x 80][y 150]
                                                       [speed 8][direction LEFT]
                                                       [color GREEN]))]
                           [speed 8]))
(define world18 (new World% [target (new Target% [x 200][y 250]
                                                [selected? false]
                                                [mx 0][my 0])]
                           [toys (list (new SquareToy% [x 72][y 150]
                                                       [speed 8][direction LEFT]
                                                       [color GREEN]))]
                           [speed 8]))


(define world-selected (new World% [target (new Target% [x 200][y 250]
                                                [selected? true]
                                                [mx 0][my 0])]
                           [toys (list (new SquareToy% [x 308][y 150]
                                                      [speed 8][direction RIGHT]
                                                      [color GREEN]))]
                           [speed 8]))


(define world-selected-res (new World% [target (new Target% [x 220][y 270]
                                                [selected? true]
                                                [mx 20][my 20])]
                           [toys (list (new SquareToy% [x 308][y 150]
                                                      [speed 8][direction RIGHT]
                                                      [color GREEN]))]
                           [speed 8]))

(define world-with-square
  (new World%
       [target (new Target% [x HALF-CANVAS-WIDTH] [y HALF-CANVAS-HEIGHT]
                            [selected? false] [mx 0] [my 0])]
       [toys (list (new SquareToy% [x HALF-CANVAS-WIDTH] [y HALF-CANVAS-HEIGHT] 
                                   [speed 8] [color GREEN]))]    
       [speed 8]))

(define world-with-circle
  (new World%
       [target (new Target% [x HALF-CANVAS-WIDTH] [y HALF-CANVAS-HEIGHT]
                            [selected? false] [mx 0] [my 0])]
       [toys (list(new CircleToy% [x HALF-CANVAS-WIDTH] [y HALF-CANVAS-HEIGHT] 
                                   [count 0] [color GREEN]))]    
       [speed 8]))



;; compare-world? : World% World% ->Boolean
;; GIVEN: two worlds for comparison
;; RETURNS: true iff two worlds are same
;; EXAMPLE: as per test cases
;; STRATEGY: High Order Function Composition

(define (compare-world? world1 world2)
  (and (send (send world1 world-target) for-test:testing-case 
                     (send world2 world-target))
       (andmap
        ; Toy% Toy% -> Boolean
        ; GIVEN: two toy objects
        ; RETURNS: true iff the two toys are same
        (lambda (t1 t2) (send t1 for-test:testing-case t2))
        (send world1 get-toys)
        (send world2 get-toys))
       (equal? (send world1 world-speed) (send world2 world-speed))))

(begin-for-test
  (check-equal? (send world1 on-draw) world-on-draw
                "Test case to check on-draw of world")
  (check-equal? (send target1 get-toys) empty
                "Test case to check get toys function of target")    
  (check-equal? (send target1 on-tick) target1)
                "Test cases to check on tick of target")
                 

(begin-for-test
  (send world1 on-mouse 20 20 "button-down")
  (check-true (compare-world? world1 world-button-down)
              "Test case to check the button-down mouse event")
  (send world2 on-mouse 20 20 "button-up")
  (check-true (compare-world? world2 world2)
              "Test case to check the button-up mouse event")
  (send world-selected on-mouse 20 20 "drag")
  (check-true (compare-world?  world-selected
                               world-selected-res)
              "Test case to check the drag mouse event when target selected")
  (send world2 on-mouse 20 20 "drag")
  (check-true (compare-world?  world2 world2)
              "Test case to check the drag mouse event when target unselected")
  (send world2 on-mouse 20 20 "move")
  (check-true (compare-world?  world2 world2)
              "Test case to check the mouse event other than button-down
               button-up and drag")
  (send empty-world-for-square on-key "s")
  (check-true (compare-world?  empty-world-for-square world-with-square)
              "Test case to check the key event s")
  (send empty-world-for-circle on-key "c")
  (check-true (compare-world? empty-world-for-circle world-with-circle)
              "Test case to check the key event c")
  (send empty-world on-key " ")
  (check-true (compare-world?  empty-world empty-world)
              "Test case to check the key event other than s and c")
  (send world7 on-tick)
  (check-true (compare-world? world7 world8)
              "Test to check the default on tick function")
  (send world5 on-tick)
  (check-true (compare-world? world5 world6)
              "Test cases to check whether the circle toy changes color
               on fifth tick red-green")
  (send world15 on-tick)
  (check-true (compare-world? world15 world16)
              "Test cases to check whether the circle toy changes color
               on fifth tick green-red")
  (send world9 on-tick)
  (check-true (compare-world? world9 world10) 
              "Test case to check whether square bounces off the right wall")
  (send world11 on-tick)
  (check-true (compare-world? world11 world12) 
              "Test case to check whether square bounces off the left wall")
  (send world3 on-tick)
  (check-true (compare-world? world3 world4) 
              "Test case to check whether square is moving correctly to right")
  (send world17 on-tick)
  (check-true (compare-world? world17 world18) 
              "Test case to check whether square is moving correctly to left")
  (send target1 on-key " " )
  (check-true (send target1 for-test:testing-case target1)
              "Test case for on-key of target")
  (send world13 on-mouse 205 255 "button-down")
  (check-true (compare-world? world13 world14) 
              "Test case to check button-down in target")
  (check-true (send world-selected target-selected?) 
              "Test case for target-selected of class world"))

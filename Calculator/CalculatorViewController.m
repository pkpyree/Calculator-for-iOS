//
//  CalculatorViewController.m
//  Calculator
//
//  Created by Arno Bost on 29.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CalculatorViewController.h"
#import "CalculatorBrain.h"

@interface CalculatorViewController ()
@property (nonatomic) BOOL userIsInTheMiddleOfEnteringANumber;
@property (nonatomic) BOOL userSelectedMinusBeforeEnteringADigit;
@property (nonatomic, strong) CalculatorBrain *brain;
@property (nonatomic) id callerPortraitView;

- (void)updateUsedVariablesDisplay;
+ (void)setCalculatorBrainAndState:(CalculatorViewController *)destinationViewController calculatorBrain:(id)brain isInTheMiddleOfEnteringANumber:(BOOL)stateEntering selectedMinusBeforeEnteringADigit:(BOOL)stateMinus startDisplayString:(NSString *)startDisplay;

@end

@implementation CalculatorViewController

@synthesize display = _display;
@synthesize historyDisplay = _historyDisplay;
@synthesize variableValuesDisplay = _variableValuesDisplay;
@synthesize userIsInTheMiddleOfEnteringANumber = _userIsInTheMiddleOfEnteringANumber;
@synthesize userSelectedMinusBeforeEnteringADigit = _userSelectedMinusBeforeEnteringADigit;
@synthesize brain = _brain;
@synthesize startDisplayString = _startDisplayString;
@synthesize callerPortraitView = _callerPortraitView;

- (NSString *)getstartDisplayString;
{
    if (!_startDisplayString) _startDisplayString = @"";
    return _startDisplayString;
}

- (void)viewDidLoad
{
    self.historyDisplay.text = [CalculatorBrain descriptionOfProgram:self.brain.program];
    [self updateUsedVariablesDisplay];
    [self secureSetDisplayText:self.startDisplayString];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self viewDidLoad];
    [super viewWillAppear:animated];
}

- (void)updateUsedVariablesDisplay
{
    NSString *workString = @"";
    
    NSSet *currentSetOfVariables = [CalculatorBrain variablesUsedInProgram:self.brain.program];
    NSString *currentVariableObject;
    for (currentVariableObject in currentSetOfVariables) {
        NSNumber *valueObject=[self.brain getVariableValue:currentVariableObject];
        if (valueObject) {
            workString = [workString stringByAppendingString:[NSString stringWithFormat:@"  %@ = %@", currentVariableObject, [valueObject stringValue]]];
        } else {
            workString = [workString stringByAppendingString:[NSString stringWithFormat:@"  %@ = 0", currentVariableObject]];
        }
    }
    
    self.variableValuesDisplay.text = workString;
}


//Only use this method to change the display-text,
//thus securing that display only shows what it shall
//
//Hint: don't use the default Setter-Method for display.text
//anywhere in this CalculatorViewController.m !!!
//
- (void) secureSetDisplayText:(NSString *)newDisplayString {
    NSString *workDisplayString = @"";
    NSString *zeroString = @"0";
    NSUInteger index;
    BOOL stateMinus = NO;   //change to YES at the 1st occurance of "-"
    BOOL stateDecimal = NO; //change to YES at the 1st occurance of period
    BOOL stateFreeShotforZeroAllowed = NO; //change to YES at period or 1st occurance of digit >=1
    BOOL stateExponential = NO; //change to YES at 1st occurance of "e"
    NSString *curCharString = @"";
    NSString *prevCharString = @"";
    NSRange curRange;
    NSString *digitString = @"0123456789einf"; //allow "e" for operation results w/ large values
    
        
    //Check if newDisplayString is nil
    if (!newDisplayString) {
        workDisplayString = zeroString;
        
    //Check if newDisplayString is empty    
    } else if ([newDisplayString isEqualToString:@""]) {
        workDisplayString = zeroString;
    
    //**From now on, newDisplayString is NOT empty
    } else {
        for (index = 0; index <= ([newDisplayString length]-1); index++) {
            prevCharString = curCharString;
            curRange.length = 1;
            curRange.location = index;
            curCharString = [newDisplayString substringWithRange:curRange];
            
            //NSLog(@"Index=%i, curCharString=%@, prevCharString=%@", index, curCharString, prevCharString);
            
            //Check "-"
            if ([curCharString isEqualToString:@"-"]) {
                
                if (stateExponential) {
                    workDisplayString = [workDisplayString stringByAppendingString:@"-"];
                } else if (!stateMinus) {
                    workDisplayString = [@"-" stringByAppendingString:workDisplayString];
                    stateMinus = YES;
                };
            } 
            
            // Check period
            else if ([curCharString isEqualToString:@"."]) {
                if (!stateDecimal) {
                    if ([digitString rangeOfString:prevCharString].location == NSNotFound) {
                        workDisplayString = [workDisplayString stringByAppendingString:@"0."];
                    } else {
                        workDisplayString = [workDisplayString stringByAppendingString:@"."];
                    }
                    stateDecimal = YES;
                    stateFreeShotforZeroAllowed = YES;
                    
                }
            }
            
            // Check digits with "zero-handling"
            //
            else if ([digitString rangeOfString:curCharString].location != NSNotFound) {
                if (stateFreeShotforZeroAllowed) {
                    workDisplayString = [workDisplayString stringByAppendingString:curCharString];
                } else {
                    if ([prevCharString isEqualToString:@"0"]) {
                        workDisplayString = [[workDisplayString substringToIndex:([workDisplayString length]-1)] stringByAppendingString:curCharString];
                    } else {
                        workDisplayString = [workDisplayString stringByAppendingString:curCharString];
                    };
                    if (![curCharString isEqualToString:@"0"]) {
                        stateFreeShotforZeroAllowed = YES;
                    }
                }
                
                if ([curCharString isEqualToString:@"e"]) {
                    stateExponential = YES;
                    stateFreeShotforZeroAllowed = YES;
                }
            }
        }
    }

    //last check of workDisplayString
    if ([workDisplayString isEqualToString:@"-"]) {
       workDisplayString = @"-0";
    }
    
    //assign to display.text
    
    self.display.text = workDisplayString;
        
    //correct state information
    
    if ([workDisplayString isEqualToString:@"0"]) {
        self.userIsInTheMiddleOfEnteringANumber = NO;
    } else if ([workDisplayString isEqualToString:@"-0"]) {
        self.userIsInTheMiddleOfEnteringANumber = NO;
    }
    
}

- (CalculatorBrain *)brain {
    if (!_brain) _brain = [[CalculatorBrain alloc] init];
    return _brain;
}

- (void) setIsResultIndicator; {
/*
    NSString *sumSignLong = @" =";
    NSRange posOfSumSign = [self.historyDisplay.text rangeOfString:sumSignLong];
    if (posOfSumSign.location == NSNotFound) {
        self.historyDisplay.text = [self.historyDisplay.text stringByAppendingString: sumSignLong];
    }
*/
}

- (void) delIsResultIndicator; {
/*   
    NSString *sumSignLong = @" =";
    NSRange posOfSumSign = [self.historyDisplay.text rangeOfString:sumSignLong];
    if (posOfSumSign.location != NSNotFound) {
        self.historyDisplay.text = [self.historyDisplay.text substringToIndex:posOfSumSign.location];
    }
*/    
}

- (IBAction)digitPressed:(UIButton *)sender {
    NSString *digit = [sender currentTitle];
 
    [self delIsResultIndicator];

    if (self.userIsInTheMiddleOfEnteringANumber) {
        [self secureSetDisplayText:([self.display.text stringByAppendingString:digit])];
    } else {
        if (self.userSelectedMinusBeforeEnteringADigit) {
            [self secureSetDisplayText:[@"-" stringByAppendingString:(digit)]];
        } else {
            [self secureSetDisplayText:digit];
        }
        self.userIsInTheMiddleOfEnteringANumber = YES;
    }

}

- (IBAction)enterPressed {
    if (self.display.text) {
        
        if ([self.display.text rangeOfString:@"Error"].location == NSNotFound ) {
            [self.brain pushOperand:[self.display.text doubleValue]];
            self.userIsInTheMiddleOfEnteringANumber = NO;
            self.userSelectedMinusBeforeEnteringADigit = NO;
            
            [self delIsResultIndicator];
            self.historyDisplay.text = [CalculatorBrain descriptionOfProgram:self.brain.program];
        }
    }
}

- (IBAction)operationPressed:(UIButton *)sender {
    
    [self delIsResultIndicator];
    if (self.userIsInTheMiddleOfEnteringANumber) [self enterPressed];
    NSString *operation = sender.currentTitle;
    
    //Tweaking operation buttons without need to change of CalculatorBrain
    //Conversion of new button text to the formerly simpler keyboard strokes.
    //Side-Effect:
    //The "older" symbols still get shown in history display, but this doesn't matter.
    
    if ([operation isEqualToString:@"÷"]) {
        operation = @"/";
    } else if ([operation isEqualToString:@"×"]) {
        operation = @"*";
    } else  if ([operation isEqualToString:@"±"]) {
        operation = @"+/-";
    } else if ([operation isEqualToString:@"−"]) {
        operation = @"-";
    } 

    id resultObject = [self.brain performOperation:operation];
    self.historyDisplay.text = [CalculatorBrain descriptionOfProgram:self.brain.program];
    
    [self updateUsedVariablesDisplay];
    if ([resultObject isKindOfClass:[NSNumber class]]) {
        [self secureSetDisplayText:([NSString stringWithFormat:@"%g", [(NSNumber *)resultObject doubleValue]])];
    } else if ([resultObject isKindOfClass:[NSString class]]) {
        self.display.text = (NSString *)resultObject;
    }
    [self setIsResultIndicator];
}

- (IBAction)variableOperandPressed:(UIButton *)sender 
{
    [self delIsResultIndicator];
    if (self.userIsInTheMiddleOfEnteringANumber) [self enterPressed];
    NSString *variableOperand = sender.currentTitle;
    
    [self.brain pushVariable:variableOperand];
/*    
    self.historyDisplay.text = [self.historyDisplay.text stringByAppendingString:@" "];
    self.historyDisplay.text = [self.historyDisplay.text stringByAppendingString:variableOperand];
*/    
    self.historyDisplay.text = [CalculatorBrain descriptionOfProgram:self.brain.program];
                                
                                
    [self updateUsedVariablesDisplay];
    
    [self secureSetDisplayText:@"0"];
    [self delIsResultIndicator];
}

- (IBAction)setVariableValuesPressed:(UIButton *)sender {
    NSDictionary *myVariables;

    /* tweaked to a more elegant source code with thanks to Tawheed Abdul-Raheem
        http://piazza.com/class#summer2012/codingtogether/1176
     
        TWEAK BEGIN*/
    
    //we want to set this dictionary values to something in the model
    if (([sender.currentTitle isEqualToString:@"Test 1"]) ||    //portrait orientation view
        ([sender.currentTitle isEqualToString:@"T 1"])){        //landscape orienation view
        myVariables = [NSDictionary dictionaryWithObjectsAndKeys: 
                       [NSNumber numberWithDouble:1.0],@"x", 
                       [NSNumber numberWithDouble:3.0],@"a", 
                       [NSNumber numberWithDouble:2.0],@"b", nil];
    } else if (([sender.currentTitle isEqualToString:@"Test 2"]) ||
               ([sender.currentTitle isEqualToString:@"T 2"])){
        myVariables = [NSDictionary dictionaryWithObjectsAndKeys: 
                       [NSNumber numberWithDouble:0.5],@"x", 
                       [NSNumber numberWithDouble:4.5],@"a", 
                       [NSNumber numberWithDouble:3],@"b", nil];
    } else if (([sender.currentTitle isEqualToString:@"Test 3"])||
               ([sender.currentTitle isEqualToString:@"T 3"])){
        myVariables = [NSDictionary dictionaryWithObjectsAndKeys: 
                       [NSNumber numberWithDouble:0.0],@"x", 
                       [NSNumber numberWithDouble:5.0],@"a", nil];
    };
    
    // TWEAK END;
   
    [self.brain setVariableValues:myVariables];
    [self updateUsedVariablesDisplay];
    
    id resultObject = [CalculatorBrain runProgram:[self.brain program] usingVariableValues:myVariables];
    
    [self updateUsedVariablesDisplay];
    if ([resultObject isKindOfClass:[NSNumber class]]) {
        [self secureSetDisplayText:([NSString stringWithFormat:@"%g", [(NSNumber *)resultObject doubleValue]])];
    } else if ([resultObject isKindOfClass:[NSString class]]) {
        self.display.text = (NSString *)resultObject;
    }
    [self setIsResultIndicator];
}

- (void)undoLastOperationPressed {
    [self.brain removeTopItemFromProgram];
    
    id resultObject = [CalculatorBrain runProgram:[self.brain program] usingVariableValues:[self.brain variables]];
    
    [self updateUsedVariablesDisplay];
    self.historyDisplay.text = [CalculatorBrain descriptionOfProgram:self.brain.program];
    if ([resultObject isKindOfClass:[NSNumber class]]) {
        [self secureSetDisplayText:([NSString stringWithFormat:@"%g", [(NSNumber *)resultObject doubleValue]])];
    } else if ([resultObject isKindOfClass:[NSString class]]) {
        self.display.text = (NSString *)resultObject;
    }
    [self setIsResultIndicator];
    self.userSelectedMinusBeforeEnteringADigit = NO;
}

- (IBAction)decimalDelimiterPressed {
    if (self.userIsInTheMiddleOfEnteringANumber) {
        [self secureSetDisplayText:([self.display.text stringByAppendingString:@"."])];
    } else {
        if (self.userSelectedMinusBeforeEnteringADigit) {
            [self secureSetDisplayText:@"-."];
        } else {
            [self secureSetDisplayText:@"."];
            
        }
        self.userIsInTheMiddleOfEnteringANumber = YES;
        [self delIsResultIndicator];
    }
}

- (IBAction)clearButtonPressed {
    self.historyDisplay.text = @"";
    self.variableValuesDisplay.text = @"";
    self.display.text = @"0";
    self.userIsInTheMiddleOfEnteringANumber = NO;
    self.userSelectedMinusBeforeEnteringADigit = NO;
    [self.brain clearCalculatorBrain];
}

- (IBAction)backspacePressed {
    
    //part 1 from assignment 1: only delete last character when user is entering a number
    if (self.userIsInTheMiddleOfEnteringANumber) {
        [self secureSetDisplayText:([self.display.text substringToIndex:([self.display.text length]-1)])];
        
        //addition for assignment 2: display last operation result if user deleted last character.
        if (!self.userIsInTheMiddleOfEnteringANumber) {
            id resultObject = [CalculatorBrain runProgram:[self.brain program] usingVariableValues:[self.brain variables]];
            
            [self updateUsedVariablesDisplay];
            if ([resultObject isKindOfClass:[NSNumber class]]) {
                [self secureSetDisplayText:([NSString stringWithFormat:@"%g", [(NSNumber *)resultObject doubleValue]])];
            } else if ([resultObject isKindOfClass:[NSString class]]) {
                self.display.text = (NSString *)resultObject;
            }
            self.historyDisplay.text = [CalculatorBrain descriptionOfProgram:self.brain.program];
            [self setIsResultIndicator];
            self.userSelectedMinusBeforeEnteringADigit = NO;
        }
    } else {
    
    //addition for assignment 2:
    //if again klick at this state, remove last operation from stack and actualize display.
        [self undoLastOperationPressed];
    }
}

- (IBAction)signChangePressed:(id)sender {
    
    if (self.userIsInTheMiddleOfEnteringANumber) {
        
        BOOL saveStatePeriod = [@"." isEqualToString:([self.display.text substringFromIndex:([self.display.text length] - 1)])];
        
        //NSLog(@"DoubleValue = %g", [self.display.text doubleValue]);
        [self secureSetDisplayText:([NSString stringWithFormat:@"%g", [self.display.text doubleValue] * (-1)])];
        
        if (saveStatePeriod) {
            [self secureSetDisplayText:([self.display.text stringByAppendingString:@"."])];
        }
        [self delIsResultIndicator];
    } else {
        [self operationPressed:sender];
    }
    self.userSelectedMinusBeforeEnteringADigit = [[self.display.text substringToIndex:1] isEqualToString:@"-"];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

+ (void)setCalculatorBrainAndState:(CalculatorViewController *)destinationViewController calculatorBrain:(id)brain isInTheMiddleOfEnteringANumber:(BOOL)stateEntering selectedMinusBeforeEnteringADigit:(BOOL)stateMinus startDisplayString:(NSString *)startDisplay
{
    if (destinationViewController) {
        if (brain) destinationViewController.brain = brain;
        destinationViewController.userIsInTheMiddleOfEnteringANumber = stateEntering;
        destinationViewController.userSelectedMinusBeforeEnteringADigit = stateMinus;
        destinationViewController.startDisplayString = startDisplay;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showLandscape"]) {
        CalculatorViewController *newController = segue.destinationViewController;
        [CalculatorViewController setCalculatorBrainAndState:newController calculatorBrain:self.brain isInTheMiddleOfEnteringANumber:self.userIsInTheMiddleOfEnteringANumber selectedMinusBeforeEnteringADigit:self.userSelectedMinusBeforeEnteringADigit startDisplayString:self.display.text];
        newController.callerPortraitView = self;
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if ((toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) ||
        (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
        NSLog(@"Querformat");
        if ((self.interfaceOrientation == UIInterfaceOrientationPortrait) ||
            (self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)) {
            [self performSegueWithIdentifier:@"showLandscape" sender:self];
        }
    } else {
        NSLog(@"Hochformat");
        [CalculatorViewController setCalculatorBrainAndState:self.callerPortraitView calculatorBrain:self.brain isInTheMiddleOfEnteringANumber:self.userIsInTheMiddleOfEnteringANumber selectedMinusBeforeEnteringADigit:self.userSelectedMinusBeforeEnteringADigit startDisplayString:self.display.text];
        [self.navigationController popViewControllerAnimated:YES];
    }

}

@end

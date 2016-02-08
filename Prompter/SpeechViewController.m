//
//  SpeechViewController.m
//  Prompter
//
//  Created by Christian Villa on 8/25/15.
//  Copyright (c) 2015 Christian Villa. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import "PromptViewController.h"
#import "SpeechViewController.h"

@interface SpeechViewController () <UIActionSheetDelegate, MFMailComposeViewControllerDelegate>

@end

@implementation SpeechViewController

# pragma - View Controller Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareDateAndText];
    [self registerForKeyboardNotifications];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isMovingFromParentViewController) {
        if ([self.noteTextView.text isEqualToString:@""]) {
            if ([self.navigationItem.title isEqualToString:@"Edit Speech"]) {
                [self.managedObjectContext deleteObject:self.speechSelected];
            }
        } else {
            if ([self.navigationItem.title isEqualToString:@"New Speech"]) {
                [self saveSpeech];
            } else if ([self.navigationItem.title isEqualToString:@"Edit Speech"]) {
                NSString *text = self.speechSelected.text;
                if (![text isEqualToString:self.noteTextView.text]) {
                    [self updateSpeech];
                }
            }
        }
        [self saveManagedObjectContext];
    }
}

# pragma - Navigation Controller Methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"PromptSpeechSegue"]) {
        PromptViewController *PVC = (PromptViewController *)segue.destinationViewController;
        PVC.speechText = self.noteTextView.text;
    }
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:nil
                                                                  action:nil];
    self.navigationItem.backBarButtonItem = backButton;
}

# pragma - Text View Delegate Methods

- (void)textViewDidBeginEditing:(UITextView *)textView {
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    [self updateDateLabel];
}

# pragma - Action Sheet Delegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:@"Delete Speech"]) {
        self.noteTextView.text = @"";
        [self.navigationController popViewControllerAnimated:YES];
    }
}

# pragma - Mail Compose Delegate Methods

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

- (IBAction)emailButtonPressed:(UIButton *)sender {
    if ([MFMailComposeViewController canSendMail]) {
        [self showEmailViewWithSubject:@"You received a speech from Prompter!"
                            AndMessage:self.noteTextView.text];
    } else {
        [self showAlertViewWithTitle:@"Uh oh!"
                          AndMessage:@"You do not have an email account associated with the Apple Mail app!"];
    }
}

- (void)showEmailViewWithSubject:(NSString *)subject AndMessage:(NSString *)message {
    MFMailComposeViewController *emailComposer = [[MFMailComposeViewController alloc] init];
    [emailComposer setMailComposeDelegate:self];
    [emailComposer setSubject:subject];
    [emailComposer setMessageBody:message
                           isHTML:NO];
    [self presentViewController:emailComposer
                       animated:YES
                     completion:nil];
}

# pragma - Notification Methods

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillBeShown:(NSNotification*)notification {
    NSDictionary* userInfo = [notification userInfo];
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    self.noteTextView.contentInset = UIEdgeInsetsMake(0, 0, keyboardSize.height, 0);
    self.noteTextView.scrollIndicatorInsets = self.noteTextView.contentInset;
}

- (void)keyboardWillBeHidden:(NSNotification*)notification {
    self.noteTextView.contentInset = UIEdgeInsetsZero;
    self.noteTextView.scrollIndicatorInsets = UIEdgeInsetsZero;
}

# pragma - Core Data Methods

- (NSString *)sortDescriptorForNote {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"MM/dd/yy          HH:mm:ss a"];
    NSDate *currentDate = [[NSDate alloc] init];
    return [dateFormat stringFromDate:currentDate];
}

- (void)saveSpeech {
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Note"
                                                         inManagedObjectContext:self.managedObjectContext];
    Note *note = [[Note alloc] initWithEntity:entityDescription
               insertIntoManagedObjectContext:self.managedObjectContext];
    note.dateUpdated = self.dateLabel.text;
    note.text = self.noteTextView.text;
    note.sortDescriptor = [self sortDescriptorForNote];
}

- (void)updateSpeech {
    self.speechSelected.dateUpdated = self.dateLabel.text;
    self.speechSelected.text = self.noteTextView.text;
    self.speechSelected.sortDescriptor = [self sortDescriptorForNote];
}

- (void)saveManagedObjectContext {
    NSError *error = nil;
    [self.managedObjectContext save:&error];
    if (error) {
        [self showAlertViewWithTitle:@"Uh oh!"
                          AndMessage:@"I was unable to save your speech!"];
    }
}

# pragma - Action Methods

- (IBAction)hideButtonPressed:(UIBarButtonItem *)sender {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self.noteTextView resignFirstResponder];
}

- (IBAction)trashButtonPressed:(UIButton *)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:nil
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  destructiveButtonTitle:@"Delete Speech"
                                  otherButtonTitles:nil];
    [actionSheet showInView:self.view];
}

- (void)showAlertViewWithTitle:(NSString *)title AndMessage:(NSString *)message {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)updateDateLabel {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"MMMM dd, yyyy, h:mm a"];
    NSDate *currentDate = [[NSDate alloc] init];
    self.dateLabel.text = [dateFormat stringFromDate:currentDate];
}

- (void)prepareDateAndText {
    if ([self.navigationItem.title isEqualToString:@"New Speech"]) {
        [self updateDateLabel];
        self.noteTextView.text = @"";
    } else if ([self.navigationItem.title isEqualToString:@"Edit Speech"]) {
        self.dateLabel.text = self.speechSelected.dateUpdated;
        self.noteTextView.text = self.speechSelected.text;
    }
}

@end

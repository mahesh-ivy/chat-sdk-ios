//
//  BEditProfileTableViewController.m
//  Chat SDK
//
//  Created by Benjamin Smiley-andrews on 25/02/2015.
//  Copyright (c) 2015 deluge. All rights reserved.
//

#import "BEditDetailedProfileTableViewController.h"

#import <ChatSDK/Core.h>
#import <ChatSDK/UI.h>
#import <ChatSDK/ChatSDK-Swift.h>

#define bStatusSection 1
#define bDateFormat @"dd/MM/yyyy"

@interface BDetailedEditProfileTableViewController () {
    BOOL uploadAvatar;
}

@end

@implementation BDetailedEditProfileTableViewController

@synthesize statusTextView;
@synthesize nameTextField;
@synthesize localityTextField;
@synthesize phoneTextField;
@synthesize emailTextField;
@synthesize availabilityButton;
@synthesize availabilityCell;
@synthesize profilePictureButton;
@synthesize imagePickerController = _imagePicker;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add the save button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSBundle t:bSave] style:UIBarButtonItemStyleDone target:self action:@selector(save)];

    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    if (version.majorVersion < 13) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSBundle t:bCancel] style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    }
    
    // The tap recognizer dismisses the keyboard when the list view is tapped
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped)];
    [self.view addGestureRecognizer:_tapRecognizer];
    
    // Update the user's details
    // We use the XMPPUser protocol because we are adding extra fields
    // just for the XMPP module - the core chat code doesn't need to
    // access these fields because they're only used in the profile
    id<PUser> user =  BChatSDK.currentUser;
    BDetailedUserWrapper * userWrapper = [BDetailedUserWrapper wrapperWithUser:user];
    
    // Load the user's information
    statusTextView.text = user.statusText;
    nameTextField.text = user.name;
    localityTextField.text = userWrapper.locality;
    phoneTextField.text = user.phoneNumber;
    emailTextField.text = user.email;
    
    statusTextView.textColor = [Colors getWithName:Colors.mediumGray];
    
    // Availability
    _availabilityOptions = [BAvailabilityState options];
    
    int i = 0;
    
    for (NSArray * option in _availabilityOptions) {
        if([option.lastObject isEqualToString:user.availability]) {
            break;
        }
        i++;
    }
    
    i = i >= 0 && i < _availabilityOptions.count ? i : 0;
    
    [_availabilityPicker selectRow:i inComponent:0 animated:NO];
    [availabilityButton setTitle:[_availabilityOptions[i] firstObject] forState:UIControlStateNormal];
    
    
    //
    // Profile picture
    //
    
    // Set the profile picture
    // Does the user already have a profile picture?
    
    [profilePictureButton loadAvatarForUser:user forControlState:UIControlStateNormal];
    profilePictureButton.layer.cornerRadius = 50;
    profilePictureButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    // Hide the picker cells - they are displayed when their button is pressed
    [self cell:availabilityCell setHidden:YES];

    [self reloadDataAnimated:NO];
    
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

#pragma Profile picture update

- (IBAction)editButtonPressed:(id)sender {
    [self profilePictureButtonPressed:Nil];
}

- (IBAction)profilePictureButtonPressed:(UIButton *)sender {
    
    __weak __typeof(self) weakSelf = self;
    
    PhotoSourceActionSheet * sheet = [PhotoSourceActionSheet new];
    
    if (!_imagePicker) {
        _imagePicker = [[UIImagePickerController alloc] init];
        _imagePicker.delegate = self;
        _imagePicker.allowsEditing = YES;
    }
        
    [self presentViewController:[sheet getOnPick:^(UIImagePickerControllerSourceType type) {
        weakSelf.imagePickerController.sourceType = type;
        [weakSelf presentViewController:weakSelf.imagePickerController animated:YES completion:Nil];
    } sourceView:sender] animated:YES completion:nil];
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    _profileImage = [info objectForKey:UIImagePickerControllerEditedImage];
    
    // Get the aspect ratio
    CGSize size = _profileImage.size;
    float minDimension = MIN(size.width, size.height);
    
    // Crop to a square
    _profileImage = [UIImage imageByCroppingImage:_profileImage toSize:CGSizeMake(minDimension, minDimension)];
    _profileImage = [_profileImage resizeImageToSize:bProfilePictureSize];
    
//    float ar = size.width / size.height;
//    if (ar > 0) {
//        size.width = bProfilePictureSize.width;
//        size.height = bProfilePictureSize.width / ar;
//    } else {
//        size.width = bProfilePictureSize.height * ar;
//        size.height = bProfilePictureSize.height;
//    }
//
//    // Now reduce the image to 200x200 for the profile picture
//    _profileImage = [_profileImage resizeImageToSize:size];
    
    [profilePictureButton setImage:_profileImage forState:UIControlStateNormal];
    
    [picker dismissViewControllerAnimated:YES completion:Nil];
}

-(void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:Nil];
}

#pragma mark - Table view data source

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return _availabilityOptions.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [_availabilityOptions[row] firstObject];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    [availabilityButton setTitle:[_availabilityOptions[row] firstObject] forState:UIControlStateNormal];
}

- (IBAction)availabilityButtonPressed:(UIButton *)sender {
    BOOL hidden = ![self cellIsHidden: availabilityCell];
    [self cell:availabilityCell setHidden:hidden];
    
    if (@available(iOS 13.0, *)) {
        [sender setTintColor:hidden ? self.defaultButtonTintColor : [UIColor systemRedColor]];
    } else {
        [sender setTintColor:hidden ? self.defaultButtonTintColor : [UIColor redColor]];
    }
    
    [self reloadDataAnimated:NO];
}


-(UIColor *) defaultButtonTintColor {
    return [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
}

-(RXPromise *) logout {

    RXPromise * promise = [RXPromise new];
    
    // Clear fields
    nameTextField.text = @"";
    localityTextField.text = @"";
    phoneTextField.text = @"";
    emailTextField.text = @"";
    
    [self dismissViewControllerAnimated:NO completion:^{
        // This will prevent a strange error caused because the view is still present
        // on the stack when we try to put the login screen
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [promise resolveWithResult:[BChatSDK.auth logout]];
        });
        
    }];
    
    return promise;

}

-(void) viewTapped {
    // Resign first responder for all fields
    [nameTextField resignFirstResponder];
    [localityTextField resignFirstResponder];
    [statusTextView resignFirstResponder];
    [phoneTextField resignFirstResponder];
    [emailTextField resignFirstResponder];
}

-(void) cancel {
    [self dismissViewControllerAnimated:YES completion:Nil];
}

-(void) save {
    [self updateUserAndIndexes];
    
//    MBProgressHUD * hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    hud.labelText = [NSBundle t: bSaving];
//    self.view.userInteractionEnabled = NO;
    
    [BChatSDK.core pushUser: _profileImage != nil].thenOnMain(^id(id success) {
//        [MBProgressHUD hideHUDForView: self.view animated:YES];
//        [self dismissViewControllerAnimated:YES completion:Nil];
//        self.view.userInteractionEnabled = YES;
        return Nil;
    }, ^id(NSError * error) {
//        [self dismissViewControllerAnimated:YES completion:Nil];
//        [UIView alertWithTitle:[NSBundle t: bErrorTitle] withError:error];
//        self.view.userInteractionEnabled = YES;
        return Nil;
    });
    
    [self dismissViewControllerAnimated:YES completion:Nil];
}

-(void) updateUserAndIndexes {
    
    // Add the user to the index
    id<PUser> user = (id<PUser>) BChatSDK.currentUser;
    BDetailedUserWrapper * userWrapper = [BDetailedUserWrapper wrapperWithUser:user];
    
    [user setStatusText: statusTextView.text];
    [user setName:nameTextField.text];
    [userWrapper setLocality:localityTextField.text];
    [user setPhoneNumber:phoneTextField.text];
    [user setEmail:emailTextField.text];
    [user setAvailability:[_availabilityOptions[[_availabilityPicker selectedRowInComponent:0]] lastObject]];
    if (_profileImage) {
        [user setImage:UIImagePNGRepresentation(_profileImage)];
    }

    [BHookNotification notificationUserUpdated:user];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [textView resignFirstResponder];
}

-(BOOL) hidesBottomBarWhenPushed {
    return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == bStatusSection) {
        float height = statusTextView.heightToFitText + 16;
        height = MIN(height, 300);
        return height;
    }
    return [super tableView: tableView heightForRowAtIndexPath:indexPath];
}

#pragma Status field change height to fit text

-(void) textViewDidChange:(UITextView *)textView {
    float newHeight = [statusTextView heightToFitText];
    if (newHeight != _statusTextViewHeight) {
        _statusTextViewHeight = newHeight;
        
        [self.tableView reloadData];
        [statusTextView becomeFirstResponder];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString * newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    if (textView.heightToFitText >= 300 && newText.length > textView.text.length) {
        return NO;
    }
    return YES;
}

- (IBAction)logoutButtonPressed:(id)sender {
    [self logout];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

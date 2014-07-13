//
//  VBYoutubeShareViewController.m
//  Selfy
//
//  Created by Volodymyr Boichentsov on 17/03/2014.
//  Copyright (c) 2014 Volodymyr Boichentsov. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>

#import "VBYoutubeShareViewController.h"

#import "GTLUtilities.h"
#import "GTMHTTPUploadFetcher.h"
#import "GTMHTTPFetcherLogging.h"
#import "GTLServiceYouTube.h"
#import "GTMOAuth2Authentication.h"
#import "GTMOAuth2ViewControllerTouch.h"

#import "GTLYouTubeVideoStatus.h"
#import "GTLYouTubeVideoSnippet.h"
#import "GTLYouTubeVideo.h"
#import "GTLQueryYouTube.h"
#import "GTLYouTubePlaylistSnippet.h"
#import "GTLYouTubeVideoCategorySnippet.h"
#import "GTLYouTubeVideoCategoryListResponse.h"
#import "GTLYouTubeVideoCategory.h"
#import "GTLYouTubeConstants.h"



#import "UIPlaceHolderTextView.h"

#define kKeychainItemName @"YouTube com.sakrist.selfy"

#define CLIENT_ID @"1042945000972.apps.googleusercontent.com"
#define SECRET_ID @"xXOUMoPKEy1dQ0k3RYfxQIDH"

@interface VBYoutubeShareViewController ()
@property (nonatomic) GTLServiceYouTube *youTubeService;

@property (nonatomic) GTLServiceTicket *uploadFileTicket;
@property (nonatomic) NSURL *uploadLocationURL;  // URL for restarting an upload.

@property (nonatomic) UITextField *categoryField;
@property (nonatomic) UITextField *fieldTitle;
@property (nonatomic) UIPlaceHolderTextView *fieldDescription;
@property (nonatomic) NSMutableArray *tagsArray;

@property (nonatomic) NSMutableArray *categories;
@property (nonatomic) NSString *categoryID;

@property (nonatomic) NSString *privacyStatus;

@property (nonatomic, weak) UITextField *activeField;

@property float progressUpload;

@end

@implementation VBYoutubeShareViewController {

    NSInteger tagCount;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    tagCount = 1;
    _tagsArray = [NSMutableArray array];
    _categoryID = @"1";
    
    GTMOAuth2Authentication *auth =
    [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                       clientID:CLIENT_ID
                                                   clientSecret:SECRET_ID];
    self.youTubeService.authorizer = auth;
    
    _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine; // or you have the previous 'None' style...
    _tableView.separatorColor = [UIColor colorWithRed:0.81 green:0.81 blue:0.82 alpha:1];
    [_tableView setRowHeight:40];
    self.title = @"Publish Video";
    
    _privacyStatus = @"public";
    
    [self login:nil];
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Publish"
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(uploadVideoFile)];
    self.navigationItem.rightBarButtonItem = item;
    
}

#pragma mark - tableview

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 12+tagCount;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *CellIdentifier = @"Cell__";
    
    UITableViewCell *cell = nil;
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    if (indexPath.row == 0) {
        static NSString *CellIdentifier_image = @"Cell__image";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier_image];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier_image];
            UIImageView *imageview = [[UIImageView alloc] initWithFrame:CGRectMake(50, 10, 200, 55)];
            [imageview setImage:[UIImage imageNamed:@"Youtube"]];
            [imageview setContentMode:UIViewContentModeScaleAspectFit];
            [cell addSubview:imageview];
            [cell setBackgroundColor:self.view.backgroundColor];
        }
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    } else if (indexPath.row == 1) {
         static NSString *Cell__title = @"Cell__title";
        cell = [tableView dequeueReusableCellWithIdentifier:Cell__title];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:Cell__title];
            _fieldTitle = [[UITextField alloc] initWithFrame:CGRectMake(10, 3, 310, [_tableView rowHeight])];
            [_fieldTitle setTextColor:[UIColor colorWithRed:0 green:0.49 blue:0.98 alpha:1]];
            [_fieldTitle setBorderStyle:UITextBorderStyleNone];
            [_fieldTitle setPlaceholder:@"Title"];
            [cell addSubview:_fieldTitle];
        }
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    } else if (indexPath.row == 2) {
        static NSString *Cell__description = @"Cell__description";
        cell = [tableView dequeueReusableCellWithIdentifier:Cell__description];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:Cell__description];
            _fieldDescription = [[UIPlaceHolderTextView alloc] initWithFrame:CGRectMake(5, 0, 310, 120)];
            [_fieldDescription setFont:[UIFont systemFontOfSize:17]];
            [_fieldDescription setTextColor:[UIColor colorWithRed:0 green:0.49 blue:0.98 alpha:1]];
            _fieldDescription.placeholderColor = [UIColor colorWithRed:0.81 green:0.81 blue:0.82 alpha:1];
            [_fieldDescription setPlaceholder:@"Description"];
            [cell addSubview:_fieldDescription];
        }
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
    }  else if (indexPath.row > 3 && indexPath.row <= 3+tagCount) {
        static NSString *Cell__tag = @"Cell__tag";
        cell = [tableView dequeueReusableCellWithIdentifier:Cell__tag];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:Cell__tag];
            UITextField *field = [[UITextField alloc] initWithFrame:CGRectMake(10, 3, 310, [_tableView rowHeight])];
            [field setDelegate:self];
            [field setTextColor:[UIColor colorWithRed:0 green:0.49 blue:0.98 alpha:1]];
            [field setBorderStyle:UITextBorderStyleNone];
            [cell.contentView addSubview:field];
        }
        int index = indexPath.row-4;
        UITextField *field = [[cell.contentView subviews] lastObject];
        
        if (indexPath.row == 4) {
            [field setPlaceholder:@"Tags"];
            [field setClearButtonMode:UITextFieldViewModeNever];
        } else {
            [field setPlaceholder:@"New tag"];
            [field setClearButtonMode:UITextFieldViewModeAlways];
        }
        
        [field setTag:index];
        [field setHidden:NO];
        if (index < [_tagsArray count]) {
            [field setText:[_tagsArray objectAtIndex:index]];
        } else {
            [field setText:nil];
        }
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
    } else if (indexPath.row == 5+tagCount) {
        static NSString *Cell__category = @"Cell__category";
        cell = [tableView dequeueReusableCellWithIdentifier:Cell__category];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:Cell__category];
            cell.textLabel.text = @"Category";
            
            _categoryField = [[UITextField alloc] initWithFrame:CGRectMake(-10, 0, 0, 0)];
            [cell.contentView addSubview:_categoryField];
            
            UIPickerView *picker = [[UIPickerView alloc] init];
            [picker setBackgroundColor:[UIColor whiteColor]];
            [picker setDataSource:self];
            [picker setDelegate:self];
            _categoryField.inputView = picker;
        }
        
        if ([_categories count] > 0) {
             [cell.detailTextLabel setText:[[_categories objectAtIndex:0] objectForKey:@"title"]];
            
        }

        
        [cell setSelectionStyle:UITableViewCellSelectionStyleGray];

        
    } else if (indexPath.row == 7+tagCount) {
        static NSString *Cell__priv = @"Cell__priv";
        cell = [tableView dequeueReusableCellWithIdentifier:Cell__priv];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:Cell__priv];
            cell.textLabel.text = @"Public";
            cell.detailTextLabel.text = @"Anyone can search for and view";
            cell.detailTextLabel.font = [UIFont systemFontOfSize:11];
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            [cell.textLabel setTextColor:_fieldTitle.textColor];
        }
        [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
        
    }  else if (indexPath.row == 8+tagCount) {
        static NSString *Cell__priv = @"Cell__priv";
        cell = [tableView dequeueReusableCellWithIdentifier:Cell__priv];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:Cell__priv];
            cell.textLabel.text = @"Unlisted";
            cell.detailTextLabel.text = @"Anyone with a link can view";
            cell.detailTextLabel.font = [UIFont systemFontOfSize:11];
        }
        [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
        
    } else if (indexPath.row == 9+tagCount) {
        static NSString *Cell__priv = @"Cell__priv";
        cell = [tableView dequeueReusableCellWithIdentifier:Cell__priv];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:Cell__priv];
            cell.textLabel.text = @"Private";
            cell.detailTextLabel.text = @"Only specific YouTube users can view";
            cell.detailTextLabel.font = [UIFont systemFontOfSize:11];
        }
        [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
        
    } else {
        
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    
    if (indexPath.row == 0 || indexPath.row == 3 || indexPath.row == 4+tagCount || indexPath.row == 6+tagCount || indexPath.row == 10+tagCount) {
        [cell setBackgroundColor:self.view.backgroundColor];
    } else {
        [cell setBackgroundColor:[UIColor whiteColor]];
    }
    
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return 70;
    } else if (indexPath.row == 2) {
        return 120;
    } else if (indexPath.row >= 7+tagCount && indexPath.row <= 9+tagCount) {
        return 50;
    }
    
    
    return [tableView rowHeight];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= 7+tagCount && indexPath.row <= 9+tagCount) {

        NSArray *array = @[ [NSIndexPath indexPathForRow:tagCount+7 inSection:0],
                           [NSIndexPath indexPathForRow:tagCount+8 inSection:0],
                            [NSIndexPath indexPathForRow:tagCount+9 inSection:0]];
        
        for (NSIndexPath *p in array) {
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:p];
            [cell.textLabel setTextColor:[UIColor blackColor]];
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        [cell.textLabel setTextColor:_fieldTitle.textColor];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        if (indexPath.row == 7+tagCount) {
            _privacyStatus = @"public";
        } else if (indexPath.row == 8+tagCount) {
            _privacyStatus = @"unlisted";
        } else {
            _privacyStatus = @"private";
        }
        
        
    } else if (indexPath.row == 5+tagCount) {
        [_categoryField becomeFirstResponder];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else {
        [_activeField resignFirstResponder];
        [_fieldTitle resignFirstResponder];
        [_fieldDescription resignFirstResponder];
        [_categoryField resignFirstResponder];
    }
}


- (void) scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [_categoryField resignFirstResponder];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    UITableViewCell *cell = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:5+tagCount inSection:0]];
    [cell.detailTextLabel setText:[[_categories objectAtIndex:row] objectForKey:@"title"]];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    _categoryID = [[_categories objectAtIndex:row] objectForKey:@"id"];
    return [[_categories objectAtIndex:row] objectForKey:@"title"];
}

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [_categories count];
}


- (void) textFieldDidBeginEditing:(UITextField *)textField {
    _activeField = textField;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (textField.tag+1 == tagCount && [text length] > 0) {
        tagCount++;
        NSIndexPath *path1 = [NSIndexPath indexPathForRow:tagCount+3 inSection:0];
        NSArray *indexArray = [NSArray arrayWithObjects:path1,nil];
        [_tableView insertRowsAtIndexPaths:indexArray withRowAnimation:UITableViewRowAnimationBottom];
    } else if (textField.tag+2 == tagCount && [text length] == 0) {
        [self deleteCell:[NSNumber numberWithInt:textField.tag+5]];
    }
        
    return YES;
}


- (void) textFieldDidEndEditing:(UITextField *)textField {
    if (textField.tag < [_tagsArray count]) {
        [_tagsArray replaceObjectAtIndex:textField.tag withObject:textField.text];
    } else {
        [_tagsArray addObject:textField.text];
    }
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    [textField resignFirstResponder];
    [textField setHidden:YES];
    [_tagsArray removeObjectAtIndex:textField.tag];
    [self deleteCell:[NSNumber numberWithInt:(int)textField.tag+4]];
    return NO;
}

- (void) deleteCell:(NSNumber*)cellnum {
    tagCount--;
    NSInteger index = [cellnum intValue];
    NSIndexPath *path1 = [NSIndexPath indexPathForRow:index inSection:0];
    NSArray *indexArray = [NSArray arrayWithObjects:path1,nil];
    [_tableView deleteRowsAtIndexPaths:indexArray withRowAnimation:UITableViewRowAnimationFade];
    
    
    NSMutableArray *indices = [NSMutableArray array];
    for (int i = index; i < index+(tagCount-(index-4)); i++ ) {
        [indices addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    
    [_tableView reloadRowsAtIndexPaths:indices withRowAnimation:UITableViewRowAnimationNone];
}


#pragma mark - Youtube


- (IBAction) login:(id)sender {

    if ([self.youTubeService.authorizer canAuthorize]) {
        [self fetchVideoCategories];
        return;
    }
    
    GTMOAuth2ViewControllerTouch *windowController =
    [GTMOAuth2ViewControllerTouch controllerWithScope:kGTLAuthScopeYouTube
                                          clientID:CLIENT_ID
                                      clientSecret:SECRET_ID
                                  keychainItemName:kKeychainItemName
                                             delegate:self
                                     finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    
    
    [self.navigationController presentViewController:windowController animated:YES completion:nil];
}

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)authResult
                 error:(NSError *)error {
    if (error != nil) {
//        [Utils showAlert:@"Authentication Error" message:error.localizedDescription];
//        _youTubeService.authorizer = nil;
    } else {
        self.youTubeService.authorizer = authResult;
    }
    
    [viewController dismissViewControllerAnimated:YES completion:nil];
    
    [self fetchVideoCategories];
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (GTLServiceYouTube *)youTubeService {
    static GTLServiceYouTube *service;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[GTLServiceYouTube alloc] init];
        
        // Have the service object set tickets to fetch consecutive pages
        // of the feed so we do not need to manually fetch them.
        service.shouldFetchNextPages = YES;
        
        // Have the service object set tickets to retry temporary error conditions
        // automatically.
        service.retryEnabled = YES;
    });
    return service;
}

- (void) fetchVideoCategories {
    // For uploading, we want the category popup to have a list of all categories
    // that may be assigned to a video.
    GTLServiceYouTube *service = self.youTubeService;
    
    GTLQueryYouTube *query = [GTLQueryYouTube queryForVideoCategoriesListWithPart:@"snippet,id"];
    query.regionCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    
    _categories = [NSMutableArray array];
    
    [service executeQuery:query
        completionHandler:^(GTLServiceTicket *ticket,
                            GTLYouTubeVideoCategoryListResponse *categoryList,
                            NSError *error) {
            if (error) {
                NSLog(@"Could not fetch video category list: %@", error);
            } else {
                // We will build a menu with the category names as menu item titles,
                // and category ID strings as the menu item represented
                // objects.
                
                for (GTLYouTubeVideoCategory *category in categoryList) {
                    GTLYouTubeVideoCategorySnippet *snip = category.snippet;
                    NSString *title = snip.title;
                    NSString *categoryID = category.identifier;
                    
                    [_categories addObject: @{@"title": title, @"id": categoryID}];
                    
                }
                
                NSLog(@"%@", _categories);
                [_tableView reloadData];
            }
        }];
}



#pragma mark - Upload

- (void) uploadVideoFile {
    // Collect the metadata for the upload from the user interface.
    
    // Status.
    GTLYouTubeVideoStatus *status = [GTLYouTubeVideoStatus object];
    
    // private or unlisted
    status.privacyStatus = _privacyStatus;
    
    if ([[_fieldTitle.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) {
        [self displayAlert:@"Please write title."
                    format:nil];
        return;
    }

    if ([[_fieldDescription.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) {
        [self displayAlert:@"Please write description."
                    format:nil];
        return;
    }

    
    // Snippet.
    GTLYouTubeVideoSnippet *snippet = [GTLYouTubeVideoSnippet object];
    snippet.title = _fieldTitle.text;
    NSString *desc = _fieldDescription.text;
    if ([desc length] > 0) {
        snippet.descriptionProperty = desc;
    }

    
    if (tagCount > 0) {
        
        NSMutableArray *array = [NSMutableArray array];
        
        for (int i = 4, len = 4+tagCount; i < len; i++) {
            NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
            UITableViewCell *cell = [_tableView cellForRowAtIndexPath:path];
            UITextField *field = [[cell.contentView subviews] lastObject];
            NSString *tag = [field.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([tag length] > 0) {
                [array addObject:tag];
            }
        }
        snippet.tags = array;
    }

    snippet.categoryId = _categoryID;
    
    GTLYouTubeVideo *video = [GTLYouTubeVideo object];
    video.status = status;
    video.snippet = snippet;
    
    [self uploadVideoWithVideoObject:video
             resumeUploadLocationURL:nil];
}

- (void)restartUpload {
    // Restart a stopped upload, using the location URL from the previous
    // upload attempt
    if (_uploadLocationURL == nil) return;
    
    // Since we are restarting an upload, we do not need to add metadata to the
    // video object.
    GTLYouTubeVideo *video = [GTLYouTubeVideo object];
    
    [self uploadVideoWithVideoObject:video
             resumeUploadLocationURL:_uploadLocationURL];
}

- (void)uploadVideoWithVideoObject:(GTLYouTubeVideo *)video
           resumeUploadLocationURL:(NSURL *)locationURL {
    // Get a file handle for the upload data.
    NSString *path = _filePath;
    NSString *filename = [path lastPathComponent];
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (fileHandle) {
        NSString *mimeType = [self MIMETypeForFilename:filename
                                       defaultMIMEType:@"video/mov"];
        GTLUploadParameters *uploadParameters =
        [GTLUploadParameters uploadParametersWithFileHandle:fileHandle
                                                   MIMEType:mimeType];
        uploadParameters.uploadLocationURL = locationURL;
        
        GTLQueryYouTube *query = [GTLQueryYouTube queryForVideosInsertWithObject:video
                                                                            part:@"snippet,status"
                                                                uploadParameters:uploadParameters];
        
        GTLServiceYouTube *service = self.youTubeService;
        _uploadFileTicket = [service executeQuery:query
                                completionHandler:^(GTLServiceTicket *ticket,
                                                    GTLYouTubeVideo *uploadedVideo,
                                                    NSError *error) {
                                    // Callback
                                    _uploadFileTicket = nil;
                                    if (error == nil) {
                                        [self displayAlert:@"Uploaded"
                                                    format:@"Uploaded file \"%@\"", uploadedVideo.snippet.title];
                                        
//                                        if ([_playlistPopup selectedTag] == kUploadsTag) {
                                            // Refresh the displayed uploads playlist.
//                                            [self fetchSelectedPlaylist];
//                                        }
                                    } else {
                                        [self displayAlert:@"Upload Failed!"
                                                    format:nil];
                                    }
                                    
//                                    [_uploadProgressIndicator setDoubleValue:0.0];
                                    _uploadLocationURL = nil;
                                    [self updateUI];
                                }];
        
        _uploadFileTicket.uploadProgressBlock = ^(GTLServiceTicket *ticket,
                                                  unsigned long long numberOfBytesRead,
                                                  unsigned long long dataLength) {
            self.progressUpload = numberOfBytesRead/dataLength;
        };
        
        // To allow restarting after stopping, we need to track the upload location
        // URL.
        //
        // For compatibility with systems that do not support Objective-C blocks
        // (iOS 3 and Mac OS X 10.5), the location URL may also be obtained in the
        // progress callback as ((GTMHTTPUploadFetcher *)[ticket objectFetcher]).locationURL
        
        GTMHTTPUploadFetcher *uploadFetcher = (GTMHTTPUploadFetcher *)[_uploadFileTicket objectFetcher];
        uploadFetcher.locationChangeBlock = ^(NSURL *url) {
            _uploadLocationURL = url;
            [self updateUI];
        };
        
        [self updateUI];
    } else {
        // Could not read file data.
        [self displayAlert:@"File Not Found" format:@"Path: %@", path];
    }
}

- (NSString *)MIMETypeForFilename:(NSString *)filename
                  defaultMIMEType:(NSString *)defaultType {
    NSString *result = defaultType;
    NSString *extension = [filename pathExtension];
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                            (__bridge CFStringRef)extension, NULL);
    if (uti) {
        CFStringRef cfMIMEType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
        if (cfMIMEType) {
            result = CFBridgingRelease(cfMIMEType);
        }
        CFRelease(uti);
    }
    return result;
}


- (void)displayAlert:(NSString *)title format:(NSString *)format, ... {
    NSString *result = format;
    if (format) {
        va_list argList;
        va_start(argList, format);
        result = [[NSString alloc] initWithFormat:format
                                        arguments:argList];
        va_end(argList);
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:result
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
    
}

- (void) updateUI {

}


@end

//
//  ViewController.m
//  类似微信中将手机号码添加到手机通讯录中
//
//  Created by Kevin's MacBook Pro on 16/9/11.
//  Copyright © 2016年 Kevin's MacBook Pro. All rights reserved.
//

#import "ViewController.h"


#define iOS7Later ([UIDevice currentDevice].systemVersion.floatValue >= 7.0f)
#define iOS8Later ([UIDevice currentDevice].systemVersion.floatValue >= 8.0f)
#define iOS9Later ([UIDevice currentDevice].systemVersion.floatValue >= 9.0f)
#define iOS9_1Later ([UIDevice currentDevice].systemVersion.floatValue >= 9.1f)

@interface ViewController (){
    NSString *linkMobile;
}
/**
 *  电话号码
 */
@property (nonatomic, weak) IBOutlet UIButton *btnNum;

- (IBAction)btnNumClick:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)btnNumClick:(id)sender {
    linkMobile = _btnNum.titleLabel.text;
    NSString *title = [NSString stringWithFormat:@"%@可能是一个电话号码,你可以",linkMobile];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"呼叫",@"添加到手机通讯录", nil];
    actionSheet.tag=2000;
    [actionSheet showInView:self.view];
}
#pragma mark - UIActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (actionSheet.tag==2000) {
        if(buttonIndex==0){
            NSURL *tmpUrl=[NSURL URLWithString:[NSString stringWithFormat:@"telprompt://%@",linkMobile]];
            [[UIApplication sharedApplication]openURL:tmpUrl];
        }
        else if(buttonIndex==1){
            NSString *title = [NSString stringWithFormat:@"%@可能是一个电话号码,你可以",linkMobile];
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"创建新联系人",@"添加到现有联系人", nil];
            actionSheet.tag=3000;
            [actionSheet showInView:self.view];
        }
    } else if (actionSheet.tag==3000){
        if (buttonIndex==0) {
            if (iOS9Later) {
                //1.创建Contact对象，须是可变
                CNMutableContact *contact = [[CNMutableContact alloc] init];
                //2.为contact赋值
                [self setValueForContact:contact existContect:NO];
                //3.创建新建联系人页面
                _controller = [CNContactViewController viewControllerForNewContact:contact];
                _controller.navigationItem.title = @"新建联系人";
                //代理内容根据自己需要实现
                _controller.delegate = self;
                //4.跳转
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:_controller];
                [self presentViewController:nc animated:YES completion:nil];
            } else {
                ABNewPersonViewController *picker = [[ABNewPersonViewController alloc] init];
                ABRecordRef newPerson = ABPersonCreate();
                ABMutableMultiValueRef multiValue = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                CFErrorRef error = NULL;
                
                ABMultiValueAddValueAndLabel(multiValue, (__bridge CFTypeRef)(linkMobile), kABPersonPhoneMobileLabel, NULL);
                ABRecordSetValue(newPerson, kABPersonPhoneProperty, multiValue , &error);
                picker.displayedPerson = newPerson;
                picker.newPersonViewDelegate = self;
                picker.navigationItem.title = @"新建联系人";
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:picker];
                [self presentViewController:nc animated:YES completion:nil];
                CFRelease(newPerson);
                CFRelease(multiValue);
            }
        } else if (buttonIndex==1) {
            if (iOS9Later) {
                //1.跳转到联系人选择页面，注意这里没有使用UINavigationController
                CNContactPickerViewController *controller = [[CNContactPickerViewController alloc] init];
                controller.delegate = self;
                [self presentViewController:controller animated:YES completion:nil];
            } else {
                ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
                picker.peoplePickerDelegate = self;
                [self presentViewController:picker animated:YES completion:nil];
            }
            
        }
    }
}
#pragma mark - iOS9以前的ABNewPersonViewController代理方法
/* 该代理方法可dismiss新添联系人页面 */
-(void)newPersonViewController:(ABNewPersonViewController *)newPersonView didCompleteWithNewPerson:(ABRecordRef)person {
    
    [newPersonView dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - iOS9以前的ABPeoplePickerNavigationController的代理方法
-(void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person {
    
    [peoplePicker dismissViewControllerAnimated:YES completion:^{
        /* 获取联系人电话 */
        ABMutableMultiValueRef phoneMulti = ABRecordCopyValue(person, kABPersonPhoneProperty);
        NSMutableArray *phones = [NSMutableArray array];
        for (CFIndex i = 0; i < ABMultiValueGetCount(phoneMulti); i++) {
            NSString *aPhone = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phoneMulti, i);
            NSString *aLabel = (__bridge_transfer NSString*)ABMultiValueCopyLabelAtIndex(phoneMulti, i);
            NSLog(@"手机号标签:%@ 手机号:%@",aLabel,aPhone);
            [phones addObject:aPhone];
            [phones addObject:aLabel];
        }
        ABNewPersonViewController *picker = [[ABNewPersonViewController alloc] init];
        ABMutableMultiValueRef multiValue = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        CFErrorRef error = NULL;
        
        ABMultiValueAddValueAndLabel(multiValue, (__bridge CFTypeRef)(linkMobile), kABPersonPhoneMobileLabel, NULL);
        for (int i = 0; i<[phones count]; i+=2) {
            
            ABMultiValueAddValueAndLabel(multiValue, (__bridge CFTypeRef)([phones objectAtIndex:i]), (__bridge CFStringRef)([phones objectAtIndex:i+1]), NULL);
        }
        ABRecordSetValue(person, kABPersonPhoneProperty, multiValue, &error);
        picker.displayedPerson = person;
        picker.newPersonViewDelegate = self;
        picker.navigationItem.title = @"新建联系人";
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:picker];
        [self presentViewController:nc animated:YES completion:nil];
        CFRelease(multiValue);
        CFRelease(phoneMulti);
    }];
}

#pragma mark - iOS9以后的CNContactViewControllerDelegate代理方法
/* 该代理方法可dismiss新添联系人页面 */
- (void)contactViewController:(CNContactViewController *)viewController didCompleteWithContact:(CNContact *)contact {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - iOS9以后的CNContactPickerDelegate的代理方法
- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContact:(CNContact *)contact{
    
    [picker dismissViewControllerAnimated:YES completion:^{
        
        //3.copy一份可写的Contact对象，不能用alloc
        CNMutableContact *con = [contact mutableCopy];
        //4.为contact赋值
        [self setValueForContact:con existContect:YES];
        //5.跳转到新建联系人页面
        CNContactViewController *controller = [CNContactViewController viewControllerForNewContact:con];
        controller.delegate = self;
        controller.navigationItem.title = @"新建联系人";
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:controller];
        [self presentViewController:nc animated:YES completion:nil];
    }];
}

/**
 *  设置要保存的contact对象
 *
 *  @param contact 联系人
 *  @param exist   是否需要重新创建
 */
- (void)setValueForContact:(CNMutableContact *)contact existContect:(BOOL)exist {
    //电话
    CNLabeledValue *phoneNumber = [CNLabeledValue labeledValueWithLabel:CNLabelPhoneNumberMobile value:[CNPhoneNumber phoneNumberWithStringValue:linkMobile]];
    if (!exist) {
        contact.phoneNumbers = @[phoneNumber];
    } else {
        //现有联系人情况
        if ([contact.phoneNumbers count] >0) {
            NSMutableArray *phoneNumbers = [[NSMutableArray alloc] initWithArray:contact.phoneNumbers];
            [phoneNumbers addObject:phoneNumber];
            contact.phoneNumbers = phoneNumbers;
        }else{
            contact.phoneNumbers = @[phoneNumber];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

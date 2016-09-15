//
//  ViewController.h
//  类似微信中将手机号码添加到手机通讯录中
//
//  Created by Kevin's MacBook Pro on 16/9/11.
//  Copyright © 2016年 Kevin's MacBook Pro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <Contacts/Contacts.h>
#import <ContactsUI/ContactsUI.h>

@interface ViewController : UIViewController<UIActionSheetDelegate,ABNewPersonViewControllerDelegate,ABPeoplePickerNavigationControllerDelegate,CNContactPickerDelegate,CNContactViewControllerDelegate>

@property (nonatomic, strong)CNContactViewController *controller;

@end


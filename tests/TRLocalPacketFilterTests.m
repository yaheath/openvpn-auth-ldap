/*
 * TRLocalPacketFilter.m vi:ts=4:sw=4:expandtab:
 * TRLocalPacketFilter Unit Tests
 *
 * Author: Landon Fuller <landonf@threerings.net>
 *
 * Copyright (c) 2006 Three Rings Design, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of Landon Fuller nor the names of any contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#ifdef HAVE_CONFIG_H
#import <config.h>
#endif

#ifdef HAVE_PF

#import <check.h>

#import "TRLocalPacketFilter.h"

#import "mockpf.h"

static TRLocalPacketFilter *pf = nil;

void setUp(void) {
    mockpf_setup();
    pf = [[TRLocalPacketFilter alloc] init];
    [pf open];
}

void tearDown(void) {
    mockpf_teardown();
    [pf release];
    pf = nil;
}

START_TEST(test_init) {
    fail_if(pf == nil);
}
END_TEST

START_TEST(test_tables) {
    TRArray *tables;
    TREnumerator *tableIter;

    fail_unless([pf tables: &tables] == PF_SUCCESS);

    /* Assume a few things about our mock pf implementation */
    tableIter = [tables objectEnumerator];

    fail_unless(strcmp([[tableIter nextObject] cString], "ips_artist") == 0);
    fail_unless(strcmp([[tableIter nextObject] cString], "ips_developer") == 0);
}
END_TEST

START_TEST(test_flushTable) {
    TRString *name = [[TRString alloc] initWithCString: "ips_artist"];
    fail_unless([pf flushTable: name] == PF_SUCCESS);
    [name release];
}
END_TEST

START_TEST(test_addAddressToTable) {
    TRString *addrString;
    TRPFAddress *pfAddress;
    TRArray *addresses;
    TRString *name;

    name = [[TRString alloc] initWithCString: "ips_artist"];
    fail_unless([pf flushTable: name] == PF_SUCCESS);

    /* Addd IPv4 Address */
    addrString = [[TRString alloc] initWithCString: "127.0.0.1"];
    pfAddress = [[TRPFAddress alloc] initWithPresentationAddress: addrString];

    fail_unless([pf addAddress: pfAddress toTable: name] == PF_SUCCESS);
    fail_unless([pf addressesFromTable: name withResult: &addresses] == PF_SUCCESS);
    fail_unless([addresses count] == 1, "Incorrect number of addresses. (expected 1, got %d)", [addresses count]);

    [addrString release];
    [pfAddress release];

    /* Test with IPv6 */
    addrString = [[TRString alloc] initWithCString: "::1"];
    pfAddress = [[TRPFAddress alloc] initWithPresentationAddress: addrString];

    fail_unless([pf addAddress: pfAddress toTable: name] == PF_SUCCESS);
    fail_unless([pf addressesFromTable: name withResult: &addresses] == PF_SUCCESS);
    fail_unless([addresses count] == 2, "Incorrect number of addresses. (expected 2, got %d)", [addresses count]);


    [addrString release];
    [pfAddress release];

    [name release];
}
END_TEST

START_TEST(test_deleteAddressFromTable) {
    TRString *addrString;
    TRPFAddress *pfAddress;
    TRArray *addresses;
    TRString *name;

    name = [[TRString alloc] initWithCString: "ips_artist"];
    fail_unless([pf flushTable: name] == PF_SUCCESS);

    /* Addd IPv4 Address */
    addrString = [[TRString alloc] initWithCString: "127.0.0.1"];
    pfAddress = [[TRPFAddress alloc] initWithPresentationAddress: addrString];

    fail_unless([pf addAddress: pfAddress toTable: name] == PF_SUCCESS);
    fail_unless([pf addressesFromTable: name withResult: &addresses] == PF_SUCCESS);
    fail_unless([addresses count] == 1, "Incorrect number of addresses. (expected 1, got %d)", [addresses count]);

    fail_unless([pf deleteAddress: pfAddress fromTable: name] == PF_SUCCESS);
    fail_unless([pf addressesFromTable: name withResult: &addresses] == PF_SUCCESS);
    fail_unless([addresses count] == 0, "Incorrect number of addresses. (expected 0, got %d)", [addresses count]);

    [addrString release];
    [pfAddress release];
    [name release];
}
END_TEST


START_TEST(test_addressesFromTable) {
    TRString *addrString;
    TRPFAddress *pfAddress;
    TRArray *addresses;
    TRString *name;

    name = [[TRString alloc] initWithCString: "ips_artist"];
    fail_unless([pf flushTable: name] == PF_SUCCESS);

    /* Addd IPv4 Address */
    addrString = [[TRString alloc] initWithCString: "127.0.0.1"];
    pfAddress = [[TRPFAddress alloc] initWithPresentationAddress: addrString];

    fail_unless([pf addAddress: pfAddress toTable: name] == PF_SUCCESS);
    fail_unless([pf addressesFromTable: name withResult: &addresses] == PF_SUCCESS);
    fail_unless([addresses count] == 1, "Incorrect number of addresses. (expected 1, got %d)", [addresses count]);

    [addrString release];
    [pfAddress release];
    [name release];
}
END_TEST

Suite *TRLocalPacketFilter_suite(void) {
    Suite *s = suite_create("TRLocalPacketFilter");

    TCase *tc_pf = tcase_create("PF Ioctl");
    tcase_add_checked_fixture(tc_pf, setUp, tearDown);
    suite_add_tcase(s, tc_pf);
    tcase_add_test(tc_pf, test_init);
    tcase_add_test(tc_pf, test_tables);
    tcase_add_test(tc_pf, test_flushTable);
    tcase_add_test(tc_pf, test_addAddressToTable);
    tcase_add_test(tc_pf, test_deleteAddressFromTable);
    tcase_add_test(tc_pf, test_addressesFromTable);

    return s;
}

#endif /* HAVE_PF */

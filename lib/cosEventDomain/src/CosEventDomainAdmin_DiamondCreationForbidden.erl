%%------------------------------------------------------------
%%
%% Implementation stub file
%% 
%% Target: CosEventDomainAdmin_DiamondCreationForbidden
%% Source: /net/isildur/ldisk/daily_build/otp_prebuild_r13b01.2009-06-07_20/otp_src_R13B01/lib/cosEventDomain/src/CosEventDomainAdmin.idl
%% IC vsn: 4.2.21
%% 
%% This file is automatically generated. DO NOT EDIT IT.
%%
%%------------------------------------------------------------

-module('CosEventDomainAdmin_DiamondCreationForbidden').
-ic_compiled("4_2_21").


-include("CosEventDomainAdmin.hrl").

-export([tc/0,id/0,name/0]).



%% returns type code
tc() -> {tk_except,"IDL:omg.org/CosEventDomainAdmin/DiamondCreationForbidden:1.0",
                   "DiamondCreationForbidden",
                   [{"diam",{tk_sequence,{tk_sequence,tk_long,0},0}}]}.

%% returns id
id() -> "IDL:omg.org/CosEventDomainAdmin/DiamondCreationForbidden:1.0".

%% returns name
name() -> "CosEventDomainAdmin_DiamondCreationForbidden".



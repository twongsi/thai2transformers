#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Nov  3 14:39:32 2020

@author: zo
"""

import warnings
import os


class REQUIRED:
    """Dummy class for checking required arguments"""
    pass


def get_field(cls, field):
    return cls.__dataclass_fields__[field]


def check_depreciated(args, warn_list):
    """
    Check if arguments in warn_list appear in args. Raise warning when found.
    """
    for arg, exp_v, warn in warn_list:
        if getattr(args, arg) != exp_v:
            warnings.warn(str(warn.args), warn.__class__)


def check_required(args):
    required = []
    kwargs = vars(args)
    for k, v in kwargs.items():
        if v == REQUIRED:
            required.append(k)
    if required:
        raise ValueError(f'{tuple(required)} are required.')


def get_file_size(f):
    old_file_position = f.tell()
    f.seek(0, os.SEEK_END)
    size = f.tell()
    f.seek(old_file_position, os.SEEK_SET)
    return size
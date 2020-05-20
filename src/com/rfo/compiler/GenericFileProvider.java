/****************************************************************************************************

BASIC! is an implementation of the Basic programming language for
Android devices.

Copyright (C) 2010 - 2016 Paul Laughton

This file is part of BASIC! for Android

    BASIC! is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    BASIC! is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with BASIC!.  If not, see <http://www.gnu.org/licenses/>.

    You may contact the author or current maintainers at http://rfobasic.freeforums.org

    Apache Commons Net
    Copyright 2001-2011 The Apache Software Foundation

    This product includes software developed by
    The Apache Software Foundation (http://www.apache.org/).

*************************************************************************************************/

// Run.InstallApk() needs this class as well as a new <provider> in the Manifest

package com.rfo.compiler;

import android.support.v4.content.FileProvider;

public class GenericFileProvider extends FileProvider {}

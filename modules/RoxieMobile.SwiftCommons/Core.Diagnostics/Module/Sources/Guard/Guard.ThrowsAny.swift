// ----------------------------------------------------------------------------
//
//  Guard.ThrowsAny.swift
//
//  @author     Alexander Bragin <bragin-av@roxiemobile.com>
//  @copyright  Copyright (c) 2017, Roxie Mobile Ltd. All rights reserved.
//  @link       http://www.roxiemobile.com/
//
// ----------------------------------------------------------------------------

import SwiftCommons

// ----------------------------------------------------------------------------

/*
using System;

namespace RoxieMobile.CSharpCommons.Diagnostics
{
    /// <summary>
    /// A set of methods useful for validating objects states. Only failed checks are throws exceptions.
    /// </summary>
    public static partial class Guard
    {
// MARK: - Methods

        /// <summary>
        /// Verifies that the exact exception or a derived exception type is thrown.
        /// </summary>
        /// <typeparam name="T">The type of the exception expected to be thrown.</typeparam>
        /// <param name="action">A delegate to the code that is expected to throw an exception when executed.</param>
        /// <param name="message">The identifying message for the <see cref="GuardError"/> (<c>null</c> okay).</param>
        /// <exception cref="ArgumentNullException">Thrown when the <see cref="action"/> is <c>null</c>.</exception>
        /// <exception cref="GuardError">Thrown when an exception was not thrown, or when an exception of the incorrect type is thrown.</exception>
        public static void ThrowsAny<T>(Action action, string message = null)
            where T : Exception
        {
            if (action == null) {
                throw new ArgumentNullException(nameof(action));
            }

            if (TryIsFailure(() => Check.ThrowsAny<T>(action), out Exception cause)) {
                throw NewGuardError(message, cause);
            }
        }

        /// <summary>
        /// Verifies that the exact exception or a derived exception type is thrown.
        /// </summary>
        /// <typeparam name="T">The type of the exception expected to be thrown.</typeparam>
        /// <param name="action">A delegate to the code that is expected to throw an exception when executed.</param>
        /// <param name="block">The function which returns identifying message for the <see cref="GuardError"/>.</param>
        /// <exception cref="ArgumentNullException">Thrown when the <see cref="action"/> or <see cref="block"/> is <c>null</c>.</exception>
        /// <exception cref="GuardError">Thrown when an exception was not thrown, or when an exception of the incorrect type is thrown.</exception>
        public static void ThrowsAny<T>(Action action, Func<string> block)
            where T : Exception
        {
            if (action == null) {
                throw new ArgumentNullException(nameof(action));
            }
            if (block == null) {
                throw new ArgumentNullException(nameof(block));
            }

            if (TryIsFailure(() => Check.ThrowsAny<T>(action), out Exception cause)) {
                throw NewGuardError(block(), cause);
            }
        }
    }
}
*/

extension Guard
{
// MARK: - Methods

    // TODO
}

// ----------------------------------------------------------------------------

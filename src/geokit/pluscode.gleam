/// # Plus Codes
/// [plus.codes](https://plus.codes)
///
/// *The algorithm and technology is known as Open Location Code. For all
/// user-facing situations, use 'Plus Codes'. I am calling them Plus Codes
/// here to avoid any confusion!*
///
/// A Plus Code is an alphanumeric string identifying a rectangular
/// cell on the Earth's surface. Longer strings pinpoint smaller cells.
///
/// The code is based on a base20 system with a specific set of characters
/// designed to make it easier to read, speak and prevent objectionable
/// combinations. There is always a plus (+) at a specific part of the
/// code - this differentiates Plus Codes from alphanumeric postal codes
/// and enables shortening.
///
/// This module aims to provide all the functionality outlined in Google's
/// API specification for Open Location Code. It also maintains various
/// conventions outlined in the spec.
///
/// ## Global vs Local
/// Plus Codes can be global or local. A global code can be identified
/// immediately, a local code is more convenient and memorable, but must
/// be paired with a nearby landmark or enclosing village/town/city/etc.
/// to place it.
///
/// ### Example
/// The location is an area by the entrance of Royal Pavilion
/// Gardens, Brighton, United Kingdom.
///
/// - Lat/Long: `50.822510, -0.138142`
/// - Global: `9C2XRVF6+2P5`
/// - Local: `RVF6+2P5 Brighton, United Kingdom`
///
/// ## Reliability
/// Not all Plus Code implementations are made reliably or work in
/// every environment. This is a known problem and is due to
/// implementation differences and complications with floating
/// point math. This implementation has been written in a way
/// that moves to integers as quickly as possible to maintain
/// location integrity.
///
/// This Plus Code implementation has been tested with all of
/// Google's reference encoding tests.
///
import geokit/latlng.{type LatLng}
import gleam/bool
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string

/// Errors returned by [`encode`](#encode) and [`decode`](#decode).
pub type PlusCodeError {
  /// The digit length requested for an encode is invalid.
  InvalidCodeLength(length: Int)
  /// [`decode`](#decode) was called with an empty string.
  EmptyString
  /// An invalid character has been passed for decoding.
  InvalidCharacter(char: String, position: Int)
  /// A local Plus Code was passed when a global Plus Code was required.
  GlobalPlusCodeRequired
  /// A global Plus Code was passed with a local Plus Code was required.
  LocalPlusCodeRequired
}

/// A structure that represents the region of a valid global
/// Plus Code.
pub type PlusCodeRegion {
  PlusCodeRegion(sw_corner: LatLng, ne_corner: LatLng, center: LatLng)
}

// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------

/// The characters used to encode lat/long information.
const base20_digits: String = "23456789CFGHJMPQRVWX"

/// Internal function that gets a Plus Code character from an Int.
/// that Int should be 0-19, else this will return an empty string.
fn int_to_digit(int: Int) -> String {
  string.slice(from: base20_digits, at_index: int, length: 1)
}

// Converts a character to a Base 20 number.
//
// Must be correct or it will return Error(Nil).
fn digit_to_int(digit: String) -> Result(Int, Nil) {
  case digit {
    "2" -> 0 |> Ok
    "3" -> 1 |> Ok
    "4" -> 2 |> Ok
    "5" -> 3 |> Ok
    "6" -> 4 |> Ok
    "7" -> 5 |> Ok
    "8" -> 6 |> Ok
    "9" -> 7 |> Ok
    "C" -> 8 |> Ok
    "F" -> 9 |> Ok
    "G" -> 10 |> Ok
    "H" -> 11 |> Ok
    "J" -> 12 |> Ok
    "M" -> 13 |> Ok
    "P" -> 14 |> Ok
    "Q" -> 15 |> Ok
    "R" -> 16 |> Ok
    "V" -> 17 |> Ok
    "W" -> 18 |> Ok
    "X" -> 19 |> Ok
    _ -> Error(Nil)
  }
}

/// The marker character between characters 8 and 10.
const plus: String = "+"

/// When a Plus code is shorter than 8 digits, the end must be
/// padded with 0s to make 8 characters, so there is always a
/// plus anchoring the code.
const padding_char: String = "0"

// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------

pub fn encode(
  point point: LatLng,
  length length: Int,
) -> Result(String, PlusCodeError) {
  // This encoding function is not outlined in the Google spec,
  // this is an improved algorithm made by a friend of mine
  // as it turned out the Google spec led to a lot of
  // inconsistency and error as it relied too much on
  // floating point math to be used safely and reliably.
  //
  // Thank you to my computer science PhD friend for
  // working out this more stable method of encoding
  // Plus Codes!
  //

  // See if the given length is valid. If not, don't
  // even bother starting.
  use <- bool.guard(
    when: !global_encoding_digit_length_is_valid(length),
    return: Error(InvalidCodeLength(length: length)),
  )

  // Plus Code conversion is very susceptible to
  // floating point math issues and discrepancies.
  //
  // The following code segments turns floating-point
  // coordinates to integers ASAP to get the flaws of
  // floating point math out of the way.
  //
  let lat_int: Int =
    point
    |> latlng.lat
    |> float.multiply(25_000_000.0)
    // Make sure in other impls this rounds
    // to the nearest whole number.
    |> float.round
    // Int
    |> fn(x) { int.clamp(x + { 90 * 25_000_000 }, 0, 180 * 25_000_000 - 1) }

  let lng_int =
    point
    |> latlng.lng
    |> float.multiply(8_192_000.0)
    // Make sure in other impls this rounds
    // to the nearest whole number.
    |> float.round
    // Int
    |> int.add(180 * 8_192_000)
    |> fn(x) {
      case x {
        l if l < 0 -> {
          x % { 360 * 8_192_000 }
          |> int.add(360 * 8_192_000)
        }
        _ -> {
          x % { 360 * 8_192_000 }
        }
      }
    }

  // Computed divisors
  //
  // Like getting Ints done first, these hard-code the divisors of
  // each level of each block of digits for maximum accuracy.
  let lat_big_divisors: List(Int) = [
    500_000_000,
    25_000_000,
    1_250_000,
    62_500,
    3125,
  ]

  let lat_small_divisors: List(Int) = [
    625,
    125,
    25,
    5,
    0,
  ]

  let lng_big_divisors: List(Int) = [
    163_840_000,
    8_192_000,
    409_600,
    20_480,
    1024,
  ]

  let lng_small_divisors: List(Int) = [
    256,
    64,
    16,
    4,
    0,
  ]

  // accumulate !!!
  //
  let big_digit_rounds = int.min(length / 2, 5)
  let small_digit_rounds = int.max(length - 10, 0)

  let all_digits: List(String) =
    encode_big_digits_acc(
      lat_int:,
      lng_int:,
      lat_divisors: list.take(lat_big_divisors, big_digit_rounds),
      lng_divisors: list.take(lng_big_divisors, big_digit_rounds),
      acc: [],
    )
    |> encode_small_digits_acc(
      lat_int:,
      lng_int:,
      lat_divisors: list.take(lat_small_divisors, small_digit_rounds),
      lng_divisors: list.take(lng_small_divisors, small_digit_rounds),
      acc: _,
    )

  let all_digit_string =
    all_digits
    |> list.fold_right(from: "", with: string.append)

  // Assemble!
  case string.length(all_digit_string) {
    // 2-6 (large areas)
    // eg. 8G2X0000+
    x if x < 8 -> {
      string.pad_end(all_digit_string, to: 8, with: padding_char)
      |> string.append(plus)
    }
    // exactly 8 :)
    // eg. 8Q7XMP52+
    x if x == 8 -> {
      string.append(all_digit_string, plus)
    }
    // 10 or more (likely buildings, plazas or entrances)
    // eg. 77M6269W+42
    _ -> {
      string.slice(from: all_digit_string, at_index: 0, length: 8)
      |> string.append(plus)
      |> string.append(string.drop_start(from: all_digit_string, up_to: 8))
    }
  }
  |> Ok
}

/// Returns digits in reverse order.
fn encode_big_digits_acc(
  lat_int lat_int: Int,
  lng_int lng_int: Int,
  lat_divisors lat_divisors: List(Int),
  lng_divisors lng_divisors: List(Int),
  acc acc: List(String),
) -> List(String) {
  case list.first(lat_divisors), list.first(lng_divisors) {
    Ok(lat_div), Ok(lng_div) -> {
      let lat_digit =
        { lat_int / lat_div }
        |> fn(x) { x % 20 }
        |> int_to_digit

      let lng_digit =
        { lng_int / lng_div }
        |> fn(x) { x % 20 }
        |> int_to_digit

      encode_big_digits_acc(
        lat_int:,
        lng_int:,
        lat_divisors: list.rest(lat_divisors) |> result.unwrap([]),
        lng_divisors: list.rest(lng_divisors) |> result.unwrap([]),
        acc: [lng_digit, lat_digit, ..acc],
      )
    }
    // error or end of list
    _, _ -> {
      acc
    }
  }
}

/// Returns digits in reverse order.
fn encode_small_digits_acc(
  lat_int lat_int: Int,
  lng_int lng_int: Int,
  lat_divisors lat_divisors: List(Int),
  lng_divisors lng_divisors: List(Int),
  acc acc: List(String),
) -> List(String) {
  case list.first(lat_divisors), list.first(lng_divisors) {
    Ok(lat_div), Ok(lng_div) -> {
      let #(lat_start, lng_start) = case lat_div, lng_div {
        0, 0 -> #(0, 0)
        _, _ -> {
          #({ lat_int / lat_div }, { lng_int / lng_div })
        }
      }
      let digit =
        { lat_start % 5 } * 4 + { lng_start % 4 }
        |> int_to_digit

      encode_small_digits_acc(
        lat_int:,
        lng_int:,
        lat_divisors: list.rest(lat_divisors) |> result.unwrap([]),
        lng_divisors: list.rest(lng_divisors) |> result.unwrap([]),
        acc: [digit, ..acc],
      )
    }

    // error or end of list
    _, _ -> {
      acc
    }
  }
}

/// Decodes a local Plus Code and returns the nearest matching full Plus Code.
pub fn recover_nearest(
  local_plus_code: String,
  near_latlng: LatLng,
) -> Result(String, PlusCodeError) {
  use <- bool.guard(
    when: is_valid_global_plus_code(local_plus_code),
    return: Error(LocalPlusCodeRequired),
  )

  // string.split(local_plus_code, on: "+")
  // |> list.head
  // |>

  //placeholder value
  let missing_big_digits = 4

  let first_digits = encode(point: near_latlng, length: missing_big_digits)

  // add the recovered big digits to the smaller digits.
  todo
}

// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// -------------- CONVERSION --------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------

/// Shortens a global Plus Code by 4 characters, to a
/// local Plus Code.
///
/// You can eliminate the first four digits of the code if:
///
/// - The center point of the feature is within 0.4 degrees
/// latitude and 0.4 degrees longitude
/// - The bounding box of the feature is less than 0.8
/// degrees high and wide.
pub fn shorten_by_4(
  global_plus_code global_plus_code: String,
) -> Result(String, PlusCodeError) {
  use <- bool.guard(
    when: is_valid_global_plus_code(global_plus_code),
    return: Error(GlobalPlusCodeRequired),
  )
  global_plus_code
  |> string.drop_end(up_to: 4)
  |> Ok
}

/// Shortens a global Plus Code by 6 charactersm, to a
/// short Plus Code.
pub fn shorten_by_6(
  global_plus_code global_plus_code: String,
) -> Result(String, PlusCodeError) {
  use <- bool.guard(
    when: is_valid_global_plus_code(global_plus_code),
    return: Error(GlobalPlusCodeRequired),
  )
  global_plus_code
  |> string.drop_end(up_to: 6)
  |> Ok
}

// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ------------------- QUERY --------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------

/// Checks if a given string is a valid Plus Code.
///
/// This does not mean that the string can be decoded
/// into `LatLng`, as it may be a local Plus Code instead
/// of a global Plus Code.
pub fn is_valid_plus_code(string: String) -> Bool {
  todo
}

/// Checks if a given string is a valid global Plus Code.
///
/// This does mean that the string can be decoded
/// into `LatLng`.
pub fn is_valid_global_plus_code(string: String) -> Bool {
  todo
}

// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------

/// Checks to see if the desired digit length for
/// encoding (without + or padding) is valid.
fn global_encoding_digit_length_is_valid(len: Int) -> Bool {
  case len {
    2 | 4 | 6 | 8 | 10 | 11 | 12 | 13 | 14 | 15 -> True
    _ -> False
  }
}

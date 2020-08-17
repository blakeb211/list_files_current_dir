package ls_command_windows
/************************************************************************************
**  Print list of files in current directory and their size using the foreign system.
*************************************************************************************/

// IMPORTS
import "core:c"
import "core:fmt"
foreign import kernel32 "system:Kernel32.lib"
import win32 "core:sys/windows"

// TYPES
wchar_t :: c.wchar_t;
c_ulong :: c.ulong;
c_longlong :: c.longlong;

BOOL :: distinct b32;
LPCWSTR :: wstring;
LPWIN32_FIND_DATAW :: ^WIN32_FIND_DATAW;
HANDLE :: distinct LPVOID;
LPVOID :: rawptr;
LPWSTR :: ^WCHAR;
WCHAR :: wchar_t;
wstring :: ^WCHAR;
DWORD :: c_ulong;
LARGE_INTEGER :: distinct c_longlong;

FILETIME :: struct {
	dwLowDateTime: DWORD,
	dwHighDateTime: DWORD,
}

WIN32_FIND_DATAW :: struct {
	dwFileAttributes: DWORD,
	ftCreationTime: FILETIME,
	ftLastAccessTime: FILETIME,
	ftLastWriteTime: FILETIME,
	nFileSizeHigh: DWORD,
	nFileSizeLow: DWORD,
	dwReserved0: DWORD,
	dwReserved1: DWORD,
	cFileName: [260]wchar_t, // #define MAX_PATH 260
	cAlternateFileName: [14]wchar_t,
}

@(default_calling_convention="stdcall")
foreign kernel32 {
	FindFirstFileW :: proc(fileName: LPCWSTR, findFileData: LPWIN32_FIND_DATAW) -> HANDLE ---
	FindNextFileW :: proc(findFile: HANDLE, findFileData: LPWIN32_FIND_DATAW) -> BOOL ---
	FindClose :: proc(findFile: HANDLE) -> BOOL ---
	GetFileSizeEx :: proc(file_handle: HANDLE, file_size: ^LARGE_INTEGER) -> BOOL ---
	GetCurrentDirectoryW :: proc(nBufferLength: DWORD, lpBuffer: LPWSTR) -> DWORD ---
}

get_curr_dir :: proc() -> []u16 {
	// a wchar is a u16 byte
	// a wstring is a ^u16

	// Determine size of name of current directory
	sz_utf16 := GetCurrentDirectoryW(0, nil); // call into OS to get size of current directory name
	dir_name_buf_wstr := make([]u16, sz_utf16); // make a u16 slice to hold the current directory name

	// Determine name of current directory 
	sz_utf16 = GetCurrentDirectoryW(DWORD(sz_utf16), &dir_name_buf_wstr[0]);

	return dir_name_buf_wstr;
}

print_files_in_directory :: proc(fname : []u16) {
	wild_card_dir_name := make([]u16, len(fname) + 2); // add two spaces for '\*'
	defer delete(wild_card_dir_name);
  copy_slice(wild_card_dir_name, fname);
	sz := len(wild_card_dir_name);
	wild_card_dir_name[sz - 1 - 2] = u16('\\'); 			// overwrite the null 
	wild_card_dir_name[sz - 1 - 1] = u16('*');
	wild_card_dir_name[sz - 1 - 0] = u16(0);    			// add the null byte back
	fmt.println("current working directory with wildcards: ", win32.utf16_to_utf8( wild_card_dir_name ));

	find_info : WIN32_FIND_DATAW;
	ptr_info  : LPWIN32_FIND_DATAW = &find_info;

	handle := FindFirstFileW(&wild_card_dir_name[0], ptr_info);
	fmt.println("first file: ", win32.utf16_to_utf8(ptr_info.cFileName[:]));

	for FindNextFileW(handle, ptr_info) != BOOL(false)  {
		fmt.println("next file: ", win32.utf16_to_utf8(ptr_info.cFileName[:]));
	}
}

main :: proc() {
	// print size info
	fmt.println("type of wchar:", typeid_of(WCHAR), "/// type of wstring", typeid_of(wstring), "/// size of DWORD", size_of(DWORD));
	fmt.println("\n");

	// get current directory
	curr_dir := get_curr_dir();
	defer delete(curr_dir);

	fmt.println("type of curr_dir: ", typeid_of(type_of(curr_dir)));
	fmt.println("current working directory: ", win32.utf16_to_utf8( curr_dir ));

	// print files in current directory
  // curr_dir is a []u16. need to add 2 chars to it	

	print_files_in_directory(curr_dir);

}








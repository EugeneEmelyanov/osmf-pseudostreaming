package org.strym.osmf.plugins.pseudostreaming.utils
{
	public class StringUtils
	{
		public static function checkExtension( str:String, value:String ):Boolean {
			if( str ) {
				var lastSumbol:int = str.lastIndexOf( '?' );
				if( lastSumbol == -1 )
					lastSumbol = str.length;
				var extension:String = str.substring( lastSumbol -3, lastSumbol );
				return value == extension;
			}
			return false;
			
		}
		
		public static function isMp4( str:String ):Boolean { 
			return checkExtension( str, 'mp4');
		}
	}
}
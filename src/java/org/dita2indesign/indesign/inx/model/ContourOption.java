/**
 * Copyright 2009 DITA2InDesign project (dita2indesign.sourceforge.net)  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at     http://www.apache.org/licenses/LICENSE-2.0  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.  n nLicensed under the Apache License, Version 2.0 (the "License"); nyou may not use this file except in compliance with the License. nYou may obtain a copy of the License at n n   http://www.apache.org/licenses/LICENSE-2.0 n nUnless required by applicable law or agreed to in writing, software ndistributed under the License is distributed on an "AS IS" BASIS, nWITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. nSee the License for the specific language governing permissions and nlimitations under the License.   Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at     http://www.apache.org/licenses/LICENSE-2.0  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License. 
 */
package org.dita2indesign.indesign.inx.model;

import java.util.ArrayList;
import java.util.List;

/**
 * Contour options;
 */
public class ContourOption extends DefaultInDesignComponent {
	
	List<String> alphaChannelPathNames = new ArrayList<String>();
	String contourPathName = null;
	ContourOptionsTypes contourType = ContourOptionsTypes.BOUNDING_BOX;
	boolean includeInsideEdges = false;
	List<String> photoshopPathNames = new ArrayList<String>();
	/**
	 * @return the alphaChannelPathNames
	 */
	public List<String> getAlphaChannelPathNames() {
		return this.alphaChannelPathNames;
	}
	/**
	 * @param alphaChannelPathNames the alphaChannelPathNames to set
	 */
	public void setAlphaChannelPathNames(List<String> alphaChannelPathNames) {
		this.alphaChannelPathNames = alphaChannelPathNames;
	}
	/**
	 * @return the contourPathName
	 */
	public String getContourPathName() {
		return this.contourPathName;
	}
	/**
	 * @param contourPathName the contourPathName to set
	 */
	public void setContourPathName(String contourPathName) {
		this.contourPathName = contourPathName;
	}
	/**
	 * @return the contourType
	 */
	public ContourOptionsTypes getContourType() {
		return this.contourType;
	}
	/**
	 * @param contourType the contourType to set
	 */
	public void setContourType(ContourOptionsTypes contourType) {
		this.contourType = contourType;
	}
	/**
	 * @return the includeInsideEdges
	 */
	public boolean isIncludeInsideEdges() {
		return this.includeInsideEdges;
	}
	/**
	 * @param includeInsideEdges the includeInsideEdges to set
	 */
	public void setIncludeInsideEdges(boolean includeInsideEdges) {
		this.includeInsideEdges = includeInsideEdges;
	}
	/**
	 * @return the photoshopPathNames
	 */
	public List<String> getPhotoshopPathNames() {
		return this.photoshopPathNames;
	}
	/**
	 * @param photoshopPathNames the photoshopPathNames to set
	 */
	public void setPhotoshopPathNames(List<String> photoshopPathNames) {
		this.photoshopPathNames = photoshopPathNames;
	}
 

}

// Copyright (c) Microsoft Corporation. All Rights Reserved.
// Licensed under the MIT License.

namespace Relecloud.Models.Search
{
    public class SearchFacet
    {
        public string FieldName { get; set; }
        public string DisplayName { get; set; }
        public IList<SearchFacetValue> Values { get; set; }

        public SearchFacet(string fieldName, string displayName, IList<SearchFacetValue> values)
        {
            this.FieldName = fieldName;
            this.DisplayName = displayName;
            this.Values = values ?? new SearchFacetValue[0];
        }
    }
}

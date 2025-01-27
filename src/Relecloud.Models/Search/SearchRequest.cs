﻿// Copyright (c) Microsoft Corporation. All Rights Reserved.
// Licensed under the MIT License.

namespace Relecloud.Models.Search
{
    public class SearchRequest
    {
        public const int PageSize = 5;

        public int CurrentPage { get; set; }

        public string Query { get; set; } = string.Empty;
        public string SortOn { get; set; } = string.Empty;
        public bool SortDescending { get; set; }
        public string PriceRange { get; set; } = string.Empty;
        public string Genre { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;

        public SearchRequest Clone()
        {
            return new SearchRequest
            {
                Query = this.Query,
                SortOn = this.SortOn,
                SortDescending = this.SortDescending,
                PriceRange = this.PriceRange,
                Genre = this.Genre,
                Location = this.Location
            };
        }
    }
}
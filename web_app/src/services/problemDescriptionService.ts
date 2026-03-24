export const fetchProblemDetails = async (slug: string): Promise<{ content: string; sampleTestCase: string; exampleTestcases: string; topicTags?: string[] }> => {
  const apiUrl = '/graphql';
  
  const requestBody = {
    query: "query questionData($titleSlug: String!) { question(titleSlug: $titleSlug) { content sampleTestCase exampleTestcases topicTags { name } } }",
    variables: { titleSlug: slug }
  };

  try {
    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(requestBody)
    });

    if (response.ok) {
      const data = await response.json();
      if (data.data && data.data.question) {
        const q = data.data.question;
        return {
          content: q.content || '',
          sampleTestCase: q.sampleTestCase || '',
          exampleTestcases: q.exampleTestcases || '',
          topicTags: q.topicTags ? q.topicTags.map((t: any) => t.name) : []
        };
      }
      throw new Error('Problem data not found in response.');
    } else {
      throw new Error(`Failed to load from LeetCode (HTTP ${response.status}).`);
    }
  } catch (error) {
    console.error('LeetCode Fetch Error:', error);
    return {
      content: "<h3>CORS Restrictions</h3><p>Direct LeetCode GraphQL calls can't be made from browsers securely without CORS proxies on localhost.</p>",
      sampleTestCase: "",
      exampleTestcases: "",
      topicTags: []
    };
  }
};

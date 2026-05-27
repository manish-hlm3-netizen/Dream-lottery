const crypto = require('crypto');

/**
 * Draw Engine - Generates cryptographically secure random winning numbers
 * and processes ticket results for a lottery draw.
 */

/**
 * Generate unique random winning numbers using crypto.randomInt
 * @param {number} count - How many numbers to pick
 * @param {number} maxNumber - Maximum number (inclusive)
 * @returns {number[]} Sorted array of unique random numbers
 */
const generateWinningNumbers = (count, maxNumber) => {
  const numbers = new Set();

  while (numbers.size < count) {
    // crypto.randomInt is cryptographically secure (range: 1 to maxNumber inclusive)
    const num = crypto.randomInt(1, maxNumber + 1);
    numbers.add(num);
  }

  return Array.from(numbers).sort((a, b) => a - b);
};

/**
 * Calculate how many numbers match between a ticket and winning numbers
 * @param {number[]} selectedNumbers - User's selected numbers
 * @param {number[]} winningNumbers - The drawn winning numbers
 * @returns {{ matchedNumbers: number[], matchCount: number }}
 */
const calculateMatches = (selectedNumbers, winningNumbers) => {
  const winSet = new Set(winningNumbers);
  const matchedNumbers = selectedNumbers.filter(num => winSet.has(num));
  return {
    matchedNumbers,
    matchCount: matchedNumbers.length
  };
};

/**
 * Determine prize amount based on match count and prize tiers
 * @param {number} matchCount - Number of matched numbers
 * @param {Array} prizes - Array of { match, label, amount } prize tiers
 * @returns {number} Prize amount (0 if no prize)
 */
const determinePrize = (matchCount, prizes) => {
  const prizeTier = prizes.find(p => p.match === matchCount);
  return prizeTier ? prizeTier.amount : 0;
};

module.exports = {
  generateWinningNumbers,
  calculateMatches,
  determinePrize
};
